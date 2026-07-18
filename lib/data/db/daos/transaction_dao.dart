import 'package:drift/drift.dart';

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
    return transaction(() async {
      final id = await into(transactions).insert(entry);
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
      };
      await _updateAccountBalance(entry.accountId.value, delta);
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
  // ────────────────────────────────────────────────────────────────────

  /// 信用卡还款(储蓄账户 → 信用卡账户,事务原子化)。
  ///
  /// 语义(ADR-0022):
  /// - 储蓄账户.balanceCents -= amountCents(钱少了)
  /// - 信用卡账户.balanceCents -= amountCents(已用减少,即可用增加)
  /// - 写 1 条 repayment transaction 记录流水,引用「还款」分类(自动 seed)
  ///
  /// 边界:
  /// - 储蓄账户余额不足 → 抛 [StateError],事务回滚
  /// - 信用卡账户不存在 / 不是信用卡类型 → 抛 [StateError]
  /// - amountCents <= 0 → 抛 [ArgumentError]
  Future<int> transferRepayment({
    required int fromSavingsAccountId,
    required int toCreditCardAccountId,
    required int amountCents,
    String? note,
  }) async {
    return transaction(() async {
      // Step 1: 校验(避免事务内失败回滚成本)
      if (amountCents <= 0) {
        throw ArgumentError('还款金额必须 > 0(当前: $amountCents)');
      }
      final savings = await db.accountDao.getById(fromSavingsAccountId);
      final creditCard = await db.accountDao.getById(toCreditCardAccountId);
      if (savings == null) {
        throw StateError('储蓄账户不存在: $fromSavingsAccountId');
      }
      if (creditCard == null) {
        throw StateError('信用卡账户不存在: $toCreditCardAccountId');
      }
      if (creditCard.type != AccountType.creditCard) {
        throw StateError(
          '目标账户不是信用卡类型: ${creditCard.name} '
          '(实际类型: ${creditCard.type.displayName})',
        );
      }
      if (savings.balanceCents < amountCents) {
        throw StateError(
          '储蓄账户余额不足: ${savings.name} '
          '(余额 ¥${_formatYuan(savings.balanceCents)},还款额 ¥${_formatYuan(amountCents)})',
        );
      }

      // Step 2: 更新余额(储蓄 -amount,信用卡已用 -amount)
      await _updateAccountBalance(fromSavingsAccountId, -amountCents);
      await _updateAccountBalance(toCreditCardAccountId, -amountCents);

      // Step 3: 写还款 transaction(直接走底层 insertTransaction,
      // 不走 insertTransaction 以避免重复扣储蓄余额)
      final repaymentCategoryId = await _getOrCreateRepaymentCategoryId();
      return await into(transactions).insert(
        TransactionsCompanion.insert(
          accountId: fromSavingsAccountId, // 主账户 = 储蓄(扣款方)
          categoryId: repaymentCategoryId,
          type: TransactionType.repayment,
          amountCents: amountCents,
          note: Value(note ?? '还${creditCard.name}'),
        ),
      );
    });
  }

  /// 更新账户余额(私有,所有 6 种账户类型通用)。
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
    final account = await db.accountDao.getById(accountId);
    if (account == null) return; // silent skip
    final newBalance = account.balanceCents + deltaCents;
    await db.accountDao.updateAccountById(
      AccountsCompanion(
        id: Value(accountId),
        balanceCents: Value(newBalance),
      ),
    );
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

  /// 分转元显示(私有 helper,错误文案用)。
  ///
  /// WHY: StateError 抛出的金额要让用户能直接读懂,¥xxx.xx 比 ¥12345 (cents) 直观。
  String _formatYuan(int cents) {
    final yuan = cents ~/ 100;
    final fen = cents.abs() % 100;
    return '$yuan.${fen.toString().padLeft(2, '0')}';
  }
}