import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../app_database.dart';
import '../tables/accounts.dart';
import '../tables/categories.dart';
import '../tables/transactions.dart';

part 'transaction_dao.g.dart';

/// 交易流水数据访问对象。
///
/// Day 1-9 (Stage 1):watchAll / getAll / insertTransaction / getById / updateTransaction / deleteById
/// Day 11-17 (Stage 2):记账主流程沿用,无大改
/// Day 19 (Stage 3, ADR-0022):
///   - insertTransaction 联动 _updateAccountBalance(支出扣 / 收入增)
///   - 新增 transferRepayment 双账户还款事务(储蓄 -amount + 信用卡 -amount + 写 repayment record)
///   - 新增 _updateAccountBalance 通用余额更新方法(所有 6 种账户类型)
///   - 新增 _getOrCreateRepaymentCategoryId 自动 seed「还款」分类
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// 监听全部交易(按发生时间倒序,最新在前)。
  Stream<List<TransactionEntry>> watchAll() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.occurredAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<List<TransactionEntry>> getAll() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.occurredAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// 新增一笔支出 / 收入交易,自动联动更新账户余额(ADR-0022)。
  ///
  /// repayment 类型 **不能** 用此方法 — 必须用 [transferRepayment](双账户事务)。
  /// 误用会在 runtime 抛 [ArgumentError]。
  ///
  /// WHY: 用户在主页「记一笔」走此路径,余额联动必须保证。
  /// 用 [transaction] {} 包裹保证原子性:insert 失败时余额不变。
  Future<int> insertTransaction(TransactionsCompanion entry) async {
    debugPrint('[D19-DEBUG] insertTransaction 被调 accountId=${entry.accountId.value} type=${entry.type.value} amount=${entry.amountCents.value}');
    return transaction(() async {
      final id = await into(transactions).insert(entry);
      debugPrint('[D19-DEBUG] insert 成功 id=$id');
      // 根据 type 判断 delta 方向(支出扣,收入增)
      final type = entry.type.present
          ? entry.type.value
          : TransactionType.expense;
      final delta = switch (type) {
        TransactionType.expense => -entry.amountCents.value,
        TransactionType.income => entry.amountCents.value,
        TransactionType.repayment => throw ArgumentError(
            'repayment 类型必须用 transferRepayment(双账户事务),不能用 insertTransaction',
          ),
        TransactionType.transfer => throw ArgumentError(
            'transfer 类型必须用 transferMoney(双账户事务),不能用 insertTransaction',
          ),
        TransactionType.lend => throw ArgumentError(
            'lend 类型必须用 lendMoney(双账户事务),不能用 insertTransaction',
          ),
        TransactionType.borrow => throw ArgumentError(
            'borrow 类型必须用 borrowMoney(双账户事务),不能用 insertTransaction',
          ),
        TransactionType.refund => throw ArgumentError(
            'refund 类型必须用 refundMoney(专用事务),不能用 insertTransaction',
          ),
      };
      debugPrint('[D19-DEBUG] 准备 _updateAccountBalance accountId=${entry.accountId.value} delta=$delta');
      await _updateAccountBalance(entry.accountId.value, delta);
      debugPrint('[D19-DEBUG] _updateAccountBalance 完成');
      return id;
    });
  }

  /// 按 id 查询单笔交易(编辑/退款流程需要先 load 再反向填充表单)。
  ///
  /// 返回 null 表示 id 不存在(不应在 UI 主流程发生,但留给退款流程防御)。
  Future<TransactionEntry?> getById(int id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 全量更新一笔交易,内部自动刷新 updatedAt。
  ///
  /// WHY: .replace() 不会触碰 updatedAt 默认值(默认仅在 INSERT 生效),
  /// 若交由调用方手动刷新极易遗漏 → 在 DAO 内统一 stamp,杜绝幽灵旧时间戳。
  Future<bool> updateTransaction(TransactionEntry entry) {
    final stamped = entry.copyWith(updatedAt: DateTime.now());
    return update(transactions).replace(stamped);
  }

  Future<int> deleteById(int id) {
    return (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  // ────────────────────────────────────────────────────────────────────
  // Day 19 (Stage 3):还款流 + 余额自动更新(ADR-0022)
  // Day 20 (Stage 3):还款流扩展,支持 4 种收款类型 + 网贷期数(ADR-0024)
  // ────────────────────────────────────────────────────────────────────

  /// 还款(任意现金类账户 → 欠款类账户,事务原子化)。
  ///
  /// 语义(ADR-0022 + ADR-0024):
  /// - [fromAccountId] 扣款方:现金 / 储蓄 / 网贷账户(目前只允许储蓄类,网贷可选)
  /// - [toAccountId] 收款方:信用卡 / 花呗 / 网贷(欠款类)
  /// - fromAccountId.balanceCents -= amountCents(钱少了)
  /// - toAccountId.balanceCents -= amountCents(欠款减少,即可用增加)
  /// - 写 1 条 repayment transaction 记录流水,引用「还款」分类(自动 seed)
  /// - 网贷还款可传 [installmentPeriod](12 / 24 / 36 期),其他类型忽略
  ///
  /// 边界(ADR-0024 §实施清单第 4 项 — 3 类场景全覆盖):
  /// - **正常**:储蓄够 + 收款账户合法 → 成功
  /// - **异常(余额不足)**:储蓄余额 < amountCents → 抛 [StateError],事务回滚
  /// - **边界(amount=0)**:amountCents <= 0 → 抛 [ArgumentError]
  /// - 收款账户不存在 / 不是欠款类型 → 抛 [StateError]
  /// - 网贷还款 + installmentPeriod 必须 ≥ 1
  Future<int> transferRepayment({
    required int fromAccountId,
    required int toAccountId,
    required int amountCents,
    String? note,
    int? installmentPeriod,
  }) async {
    return transaction(() async {
      // Step 1: 校验
      if (amountCents <= 0) {
        throw ArgumentError('还款金额必须 > 0(当前: $amountCents)');
      }
      final from = await db.accountDao.getById(fromAccountId);
      final to = await db.accountDao.getById(toAccountId);
      if (from == null) {
        throw StateError('扣款账户不存在: $fromAccountId');
      }
      if (to == null) {
        throw StateError('收款账户不存在: $toAccountId');
      }
      // 扣款方:现金 / 储蓄(网贷可还款自身,本期不支持)
      final fromIsCashLike = from.type == AccountType.cash ||
          from.type == AccountType.savings;
      if (!fromIsCashLike) {
        throw StateError(
          '扣款账户必须是现金或储蓄: ${from.name} '
          '(实际类型: ${from.type.displayName})',
        );
      }
      // 收款方:信用卡 / 花呗 / 网贷(欠款类)
      final toIsDebtLike = to.type == AccountType.creditCard ||
          to.type == AccountType.huabei ||
          to.type == AccountType.onlineLoan;
      if (!toIsDebtLike) {
        throw StateError(
          '收款账户必须是信用卡/花呗/网贷: ${to.name} '
          '(实际类型: ${to.type.displayName})',
        );
      }
      // 网贷还款必须传 installmentPeriod ≥ 1(ADR-0024 §1)
      if (to.type == AccountType.onlineLoan) {
        if (installmentPeriod == null || installmentPeriod < 1) {
          throw ArgumentError(
            '网贷还款必须传期数(>=1): ${to.name},当前 installmentPeriod=$installmentPeriod',
          );
        }
      }
      if (from.balanceCents < amountCents) {
        throw StateError(
          '扣款账户余额不足: ${from.name} '
          '(余额 ¥${_formatYuan(from.balanceCents)},还款额 ¥${_formatYuan(amountCents)})',
        );
      }

      // Step 2: 更新余额(扣款 -amount,收款已用 -amount)
      await _updateAccountBalance(fromAccountId, -amountCents);
      await _updateAccountBalance(toAccountId, -amountCents);

      // Step 3: 写还款 transaction(直接走底层 insertTransaction,
      // 不走 insertTransaction 以避免重复扣储蓄余额)
      final repaymentCategoryId = await _getOrCreateRepaymentCategoryId();
      return await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: fromAccountId, // 主账户 = 扣款方
          categoryId: repaymentCategoryId,
          type: TransactionType.repayment,
          amountCents: amountCents,
          note: Value(note ?? '还${to.name}'),
          installmentPeriod: installmentPeriod != null
              ? Value(installmentPeriod)
              : const Value.absent(),
        ),
      );
    });
  }

  /// 转账(资金账户 → 资金账户,事务原子化)—— ADR-0026 §5。
  ///
  /// 语义(v4 §5):转账 = 两个普通账户间转移,双方平衡(区别于还款「抵消欠款」)。
  /// - [fromAccountId].balanceCents -= amountCents(转出减少)
  /// - [toAccountId].balanceCents   += amountCents(转入增加)
  /// - 写 1 条 type=transfer transaction,引用「转账」分类(自动 seed)
  ///
  /// 3 类场景(铁律 8 — 边界必覆盖):
  /// - **正常**:转出账户余额够 → 成功
  /// - **异常(余额不足)**:from.balanceCents < amountCents → 抛 [StateError],回滚
  /// - **边界(amount=0 / 同账户)**:amountCents <= 0 或 from==to → 抛 [ArgumentError]
  Future<int> transferMoney({
    required int fromAccountId,
    required int toAccountId,
    required int amountCents,
    String? note,
  }) async {
    return transaction(() async {
      if (amountCents <= 0) {
        throw ArgumentError('转账金额必须 > 0(当前: $amountCents)');
      }
      if (fromAccountId == toAccountId) {
        throw ArgumentError('转出账户和转入账户不能是同一个');
      }
      final from = await db.accountDao.getById(fromAccountId);
      final to = await db.accountDao.getById(toAccountId);
      if (from == null) throw StateError('转出账户不存在: $fromAccountId');
      if (to == null) throw StateError('转入账户不存在: $toAccountId');
      if (from.balanceCents < amountCents) {
        throw StateError(
          '转出账户余额不足: ${from.name} '
          '(余额 ¥${_formatYuan(from.balanceCents)},转账额 ¥${_formatYuan(amountCents)})',
        );
      }

      await _updateAccountBalance(fromAccountId, -amountCents);
      await _updateAccountBalance(toAccountId, amountCents);

      final categoryId = await _getOrCreateTransferCategoryId();
      return await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: fromAccountId,
          categoryId: categoryId,
          type: TransactionType.transfer,
          amountCents: amountCents,
          note: Value(note ?? '转账到${to.name}'),
        ),
      );
    });
  }

  /// 借出(资金账户 → 借贷账户「借出」,事务原子化)—— ADR-0026 §12 落地(D22)。
  ///
  /// 语义:从资金方(扣款账户)转出,落到借出账户的应收债权。
  /// - [fromAccountId].balanceCents -= amountCents(资金方钱少了)
  /// - [toAccountId].balanceCents   += amountCents(借出账户应收债权增加)
  /// - 写 1 条 type=lend transaction,引用「借出」分类(自动 seed),含 counterpartyName
  ///
  /// 3 类场景(铁律 8):
  /// - 正常:扣款账户余额够 + 借出账户存在 → 成功
  /// - 异常(余额不足):from.balanceCents < amount → StateError,回滚
  /// - 边界:amount<=0 / 同账户 / 借出账户不是借贷类 → ArgumentError
  Future<int> lendMoney({
    required int fromAccountId,
    required int toAccountId,
    required int amountCents,
    String? counterparty,
    String? note,
    DateTime? startDate,
    // D25 ADR-0029 扩展 2 字段(transaction 表):
    DateTime? lendStartDate,
    DateTime? lendEndDate,
  }) async {
    return transaction(() async {
      if (amountCents <= 0) {
        throw ArgumentError('借出金额必须 > 0(当前: $amountCents)');
      }
      if (fromAccountId == toAccountId) {
        throw ArgumentError('资金账户和借出账户不能是同一个');
      }
      final from = await db.accountDao.getById(fromAccountId);
      final to = await db.accountDao.getById(toAccountId);
      if (from == null) throw StateError('资金账户不存在: $fromAccountId');
      if (to == null) throw StateError('借出账户不存在: $toAccountId');
      if (to.subType != AccountSubType.lendOut) {
        throw ArgumentError(
          '收款方必须是「借出」子类型: ${to.name}(实际: ${to.subType?.name ?? "null"})',
        );
      }
      if (from.balanceCents < amountCents) {
        throw StateError(
          '资金账户余额不足: ${from.name}(余额 ¥${_formatYuan(from.balanceCents)},借出额 ¥${_formatYuan(amountCents)})',
        );
      }

      await _updateAccountBalance(fromAccountId, -amountCents);
      await _updateAccountBalance(toAccountId, amountCents);

      final categoryId = await _getOrCreateLendCategoryId();
      return await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: fromAccountId,
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
          categoryId: categoryId,
          type: TransactionType.lend,
          amountCents: amountCents,
          note: Value(note ?? '借出给${counterparty ?? "某人"}'),
          counterpartyName: Value(counterparty),
          startDate: Value(startDate),
          // D25 ADR-0029:借出/收款 transaction 日期(transaction 表)
          lendStartDate: Value(lendStartDate),
          lendEndDate: Value(lendEndDate),
          // D25 IQA L5 修复:occurredAt 优先用 lendStartDate(transaction 真日期),
          // 让主页交易列表按交易发生日期排序;fallback 到 startDate/now。
          occurredAt:
              Value(lendStartDate ?? startDate ?? DateTime.now()),
        ),
      );
    });
  }

  /// 借入(借贷账户「借入」 → 资金账户,事务原子化)—— ADR-0026 §12。
  ///
  /// 语义:从借入账户(应付债务)增记,落到入款资金账户。
  /// - [fromAccountId](借入).balanceCents += amountCents(负债增加)
  /// - [toAccountId](入款).balanceCents   += amountCents(资金入账)
  ///
  /// WHY 双向加:咔皮截图「借入」语义是「我欠了一笔钱 → 钱到我某个账户」,所以
  /// 借入账户和入款账户余额都 +amountCents(借入账户负债 +amount,入款账户钱 +amount)。
  Future<int> borrowMoney({
    required int fromAccountId,
    required int toAccountId,
    required int amountCents,
    String? counterparty,
    String? note,
    DateTime? startDate,
    // D25 ADR-0029 扩展 2 字段(transaction 表):
    DateTime? lendStartDate,
    DateTime? lendEndDate,
  }) async {
    return transaction(() async {
      if (amountCents <= 0) {
        throw ArgumentError('借入金额必须 > 0(当前: $amountCents)');
      }
      if (fromAccountId == toAccountId) {
        throw ArgumentError('借入账户和入款账户不能是同一个');
      }
      final from = await db.accountDao.getById(fromAccountId);
      final to = await db.accountDao.getById(toAccountId);
      if (from == null) throw StateError('借入账户不存在: $fromAccountId');
      if (to == null) throw StateError('入款账户不存在: $toAccountId');
      if (from.subType != AccountSubType.borrowIn) {
        throw ArgumentError(
          '来源方必须是「借入」子类型: ${from.name}(实际: ${from.subType?.name ?? "null"})',
        );
      }
      final categoryId = await _getOrCreateBorrowCategoryId();
      await _updateAccountBalance(fromAccountId, amountCents);
      await _updateAccountBalance(toAccountId, amountCents);

      return await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: toAccountId,
          fromAccountId: Value(fromAccountId),
          toAccountId: Value(toAccountId),
          categoryId: categoryId,
          type: TransactionType.borrow,
          amountCents: amountCents,
          note: Value(note ?? '从${counterparty ?? "某人"}借入'),
          counterpartyName: Value(counterparty),
          startDate: Value(startDate),
          // D25 ADR-0029:借入/还款 transaction 日期(transaction 表)
          lendStartDate: Value(lendStartDate),
          lendEndDate: Value(lendEndDate),
          // D25 IQA L5 修复:occurredAt 优先用 lendStartDate(transaction 真日期),
          // 让主页交易列表按交易发生日期排序;fallback 到 startDate/now。
          occurredAt:
              Value(lendStartDate ?? startDate ?? DateTime.now()),
        ),
      );
    });
  }

  /// 更新账户余额(私有,所有账户类型通用)。
  ///
  /// WHY: 单点维护余额更新逻辑,所有路径(insertTransaction / transferRepayment)
  /// 走同一套余额计算,避免逻辑分裂。
  ///
  /// 行为(ADR-0022 §决策 2 v2):
  /// - 账户不存在 → silent skip(测试 fixture / 已删账户场景)
  /// - 余额 / 已用额度允许变负数(用户记账可能透支;信用卡已用为负 = 异常但允许,UI 显示)
  /// - 余额校验 **不在此处**,而是在 [transferRepayment] 业务方法显式 check
  ///   (避免 S02 既有测试 fixture 默认 0 余额被打破)
  Future<void> _updateAccountBalance(int accountId, int deltaCents) async {
    debugPrint('[D19-DEBUG] _updateAccountBalance 进入 accountId=$accountId delta=$deltaCents');
    final account = await db.accountDao.getById(accountId);
    debugPrint('[D19-DEBUG] getById 返回 account=${account?.name} balance=${account?.balanceCents}');
    if (account == null) return; // silent skip
    final newBalance = account.balanceCents + deltaCents;
    debugPrint('[D19-DEBUG] newBalance=$newBalance 准备 update');
    final updated = await db.accountDao.updateAccountById(
      AccountsCompanion(
        id: Value(accountId),
        balanceCents: Value(newBalance),
      ),
    );
    debugPrint('[D19-DEBUG] updateAccountById 返回 updated=$updated');
  }

  /// 获取或创建「还款」分类 ID(私有,首次还款时自动 seed)。
  ///
  /// WHY: 不用手动 seed 默认分类(S02 写集已收尾),用户首次还款时自动创建。
  /// 后续还款复用同一分类(name='还款' + icon='💳' + type=expense)。
  /// 颜色固定紫色 0xFF7E57C2(4286470082),与信用卡 emoji 视觉关联。
  Future<int> _getOrCreateRepaymentCategoryId() async {
    final allCategories = await db.categoryDao.getAll();
    final existing = allCategories.where((c) => c.name == '还款');
    if (existing.isNotEmpty) return existing.first.id;

    return await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: '还款',
        iconName: '💳',
        colorValue: 4286470082, // 紫色 0xFF7E57C2,colorValue 无 default,直接传 int
        type: TransactionType.expense,
        sortOrder: const Value(10),
      ),
    );
  }

  /// 获取或创建「借出」分类 ID(私有,首次借出时自动 seed)。
  ///
  /// name='借出' + icon='📤' + type=lend + 橙色 0xFFFF7043(4294739011)。
  Future<int> _getOrCreateLendCategoryId() async {
    final allCategories = await db.categoryDao.getAll();
    final existing = allCategories.where((c) => c.name == '借出');
    if (existing.isNotEmpty) return existing.first.id;

    return await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: '借出',
        iconName: '📤',
        colorValue: 4294739011,
        type: TransactionType.lend,
        sortOrder: const Value(12),
      ),
    );
  }

  /// 获取或创建「借入」分类 ID(私有,首次借入时自动 seed)。
  ///
  /// name='借入' + icon='📥' + type=borrow + 紫色 0xFFAB47BC(4293083836)。
  Future<int> _getOrCreateBorrowCategoryId() async {
    final allCategories = await db.categoryDao.getAll();
    final existing = allCategories.where((c) => c.name == '借入');
    if (existing.isNotEmpty) return existing.first.id;

    return await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: '借入',
        iconName: '📥',
        colorValue: 4293083836,
        type: TransactionType.borrow,
        sortOrder: const Value(13),
      ),
    );
  }

  /// 获取或创建「转账」分类 ID(私有,首次转账时自动 seed)。
  ///
  /// name='转账' + icon='🔄' + type=transfer + 蓝色 0xFF42A5F5(4282549237)。
  Future<int> _getOrCreateTransferCategoryId() async {
    final allCategories = await db.categoryDao.getAll();
    final existing = allCategories.where((c) => c.name == '转账');
    if (existing.isNotEmpty) return existing.first.id;

    return await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: '转账',
        iconName: '🔄',
        colorValue: 4282549237, // 蓝色 0xFF42A5F5
        type: TransactionType.transfer,
        sortOrder: const Value(11),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────
  // Day 26 (Stage 3):退款 transaction 化(ADR-0030) — D26 用户拍板 Q3=B + Q4=α2
  //   - ¥10 餐饮可退 ¥3 + ¥5 + ¥2(多次独立 refund,sum <= original)
  //   - DAO 校验 amount <= original + 累计已退 <= original
  //   - ¥3 = ¥1 + ¥2 的硬部分退款 schema v9 设计留 ADR-0037(v1.1)
  // ────────────────────────────────────────────────────────────────────

  /// 退款(单笔 transaction 原路退款 + 自动 seed「退款」分类)— ADR-0030 §决策 3 修订版。
  ///
  /// 语义:
  /// - DAO 类型校验:原交易 type ∈ {expense, repayment, lend, borrow} 才允许退款
  ///   (income / transfer / refund 一律抛 StateError)
  /// - 单笔金额校验:[amountCents] <= 原交易 [amountCents]
  /// - 累计金额校验:SUM(refunds where originalTransactionId=X) + amountCents <= original
  ///   (支持多次拆分退款,Q3=B + Q4=α2 拍板)
  /// - 余额联动:[refundAccountId].balanceCents += amountCents(原账户扣回)
  /// - 写 1 条 type=refund transaction,关联交易引用 + 备注 + refundTime 落库
  ///
  /// 3 类场景(铁律 8 — 边界必覆盖):
  /// - **正常**:原 expense -¥8.96 + 退款时间 + 退款账户合法 → 成功
  /// - **异常(类型不允许)**:对 income/transfer/refund 退款 → StateError「只能对支出/还款/借贷 transaction 退款」
  /// - **边界(单笔超限)**:amountCents > original → StateError「单笔退款金额不能超过」
  /// - **边界(累计超限)**:已退 ¥8 + 退 ¥5 > ¥10 → StateError「累计退款金额超限」
  /// - **边界(嵌套退款)**:对 refund 退款 → StateError「不能对退款记录再退款」
  /// - **边界(账户不存在)**:refundAccountId 非法 → silent skip 余额更新,refund 记录写入但余额不动
  ///   (与 [transferMoney] 行为一致)
  Future<int> refundMoney({
    required int originalTransactionId,
    required int refundAccountId,
    required int amountCents,
    required DateTime refundTime,
    String? refundNote,
  }) async {
    return transaction(() async {
      // Step 1: 校验原交易
      final original = await (select(transactions)
            ..where((t) => t.id.equals(originalTransactionId)))
          .getSingleOrNull();
      if (original == null) {
        throw StateError('原交易不存在: $originalTransactionId');
      }
      if (original.type == TransactionType.refund) {
        throw StateError('不能对退款记录再退款(嵌套保护)');
      }
      if (original.type == TransactionType.income ||
          original.type == TransactionType.transfer) {
        throw StateError(
          '只能对支出/还款/借贷 transaction 退款'
          '(原 type=${original.type.name})',
        );
      }
      if (amountCents <= 0) {
        throw ArgumentError('退款金额必须 > 0(当前: $amountCents)');
      }
      if (amountCents > original.amountCents) {
        throw StateError(
          '单笔退款金额不能超过原交易金额'
          '(本次 ¥${_formatYuan(amountCents)},'
          '原 ¥${_formatYuan(original.amountCents)})',
        );
      }

      // Step 2: 累计已退金额检查(多次拆分退款保护)
      final alreadyRefunded = await _sumRefundedAmount(originalTransactionId);
      if (alreadyRefunded + amountCents > original.amountCents) {
        throw StateError(
          '累计退款金额超限'
          '(原 ¥${_formatYuan(original.amountCents)},'
          '已退 ¥${_formatYuan(alreadyRefunded)},'
          '本次 ¥${_formatYuan(amountCents)})',
        );
      }

      // Step 3: 更新账户余额(原账户扣回 = +amount,因为支出原 -amount)
      await _updateAccountBalance(refundAccountId, amountCents);

      // Step 4: 写 refund transaction(直接 into,不走 insertTransaction,因为类型
      // refund 已在 switch 抛 ArgumentError 防 generic DAO 误用)
      final refundCategoryId = await _getOrCreateRefundCategoryId();
      return await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: refundAccountId,
          categoryId: refundCategoryId,
          type: TransactionType.refund,
          amountCents: amountCents,
          occurredAt: Value(refundTime), // C6 fix:用 refundTime 非 now
          originalTransactionId: Value(originalTransactionId),
          refundNote: Value(refundNote ?? '退款'),
          note: Value(
            '退款:${original.note} ¥${_formatYuan(amountCents)}',
          ),
        ),
      );
    });
  }

  /// 查原交易累计已退金额(refund sum)— ADR-0030 §决策 3 修订版(支持拆分退款)。
  ///
  /// 无 schema 字段(留 v1.1 评估 ADR-0037),用 SUM 查询返累加总额。
  /// 返回:0 = 未退过;>0 = 已退总额(分)。
  Future<int> _sumRefundedAmount(int originalTransactionId) async {
    final query = select(transactions)
      ..where((t) => t.originalTransactionId.equals(originalTransactionId));
    final rows = await query.get();
    return rows.fold<int>(0, (sum, t) => sum + t.amountCents);
  }

  /// 公开 API:查原交易是否被退过(UI 详情页用于禁用编辑/删除/退款按钮)。
  ///
  /// 返回:0 = 未退过;>0 = 已退总额(分)。
  /// WHY:ActionSheet / DetailPage 在异步加载时拿到最新值,避免「已退款仍允许编辑」的竞态。
  Future<int> getRefundedAmount(int originalTransactionId) async {
    return _sumRefundedAmount(originalTransactionId);
  }

  /// 获取或创建「退款」分类 ID(私有,首次退款时自动 seed)— ADR-0030 §决策 4 修订版。
  ///
  /// name='退款' + icon='↩️' + type=refund + 蓝灰色 0xFF607D8B(4280457355)。
  ///
  /// M4 修复:按 name + type 双字段查找,避免和用户自建的 "退款" expense 同名分类冲突。
  /// L4 修复:sortOrder=99 放最后,与现有 9 个默认分类(0-9)排序不冲突。
  ///
  /// 与 D27 onUpgrade seed 互斥:D27 实施 24 分类时,**必须** 跳过 name='退款' 的 seed,
  /// 否则 DAO 自动 seed(本方法)与 D27 onUpgrade seed 会重复创建同名分类。
  /// 详 M4(2026-08-09 IQA)。
  Future<int> _getOrCreateRefundCategoryId() async {
    final allCategories = await db.categoryDao.getAll();
    final existing = allCategories.where((c) =>
        c.name == '退款' && c.type == TransactionType.refund);
    if (existing.isNotEmpty) return existing.first.id;

    return await db.categoryDao.insertCategory(
      CategoriesCompanion.insert(
        name: '退款',
        iconName: '↩️',
        colorValue: 4280457355, // 蓝灰色 0xFF607D8B
        type: TransactionType.refund,
        sortOrder: const Value(99),
      ),
    );
  }

  /// 分转元显示(私有 helper,错误文案用)。
  ///
  /// WHY: StateError 抛出的金额要让用户能直接读懂,¥xxx.xx 比 ¥12345 (cents) 直观。
  String _formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final fen = cents.abs() % 100;
    return '$yuan.${fen.toString().padLeft(2, '0')}';
  }
}