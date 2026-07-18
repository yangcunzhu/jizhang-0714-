// TransactionDao 单测(Day 19,Stage 3 — ADR-0022)。
//
// 覆盖范围:
// 1. insertTransaction 联动 _updateAccountBalance(支出扣 / 收入增)
// 2. insertTransaction 拒绝 repayment 类型(必须用 transferRepayment)
// 3. transferRepayment 完整路径(储蓄 -amount + 信用卡 -amount + 写 repayment)
// 4. transferRepayment 边界:余额不足 / 信用卡不存在 / 储蓄不是储蓄 / 信用卡不是信用卡 / amount <= 0
// 5. _getOrCreateRepaymentCategoryId 自动 seed「还款」分类
//
// 测试策略:用 AppDatabase.forTesting(NativeDatabase.memory()) + 每个测试
// 自己 setUp 现金账户 + 信用卡账户,确保状态隔离。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';

void main() {
  group('TransactionDao — Day 19 (Stage 3 ADR-0022)', () {
    late AppDatabase db;
    late int cashAccountId;
    late int creditCardAccountId;

    /// 每个测试 setUp:建库 + 1 现金账户(余额 1000 元)+ 1 信用卡账户(额度 50000,余额 0)
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      cashAccountId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '现金',
          type: const Value(AccountType.cash),
          balanceCents: const Value(100000), // 1000 元
        ),
      );
      creditCardAccountId = await db.accountDao.insertAccount(
        AccountsCompanion.insert(
          name: '招行信用卡',
          type: const Value(AccountType.creditCard),
          balanceCents: const Value(0), // 信用卡余额 = 已用额度(0 = 没用过)
          creditLimit: const Value(5000000), // 50000 元
          billingDay: const Value(5),
          dueDay: const Value(25),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    // ────────────────────────────────────────────────────────────────
    // 1. insertTransaction 联动余额(支出扣 / 收入增)
    // ────────────────────────────────────────────────────────────────

    group('insertTransaction 联动余额', () {
      test('支出扣减余额(默认 1000 元 → 支出 12.99 元 → 987.01 元)', () async {
        // 取一个「餐饮」分类 id
        final mealCategory = (await db.categoryDao.getAll())
            .firstWhere((c) => c.name == '餐饮');

        await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            accountId: cashAccountId,
            categoryId: mealCategory.id,
            type: TransactionType.expense,
            amountCents: 1299,
          ),
        );

        final cash = await db.accountDao.getById(cashAccountId);
        expect(cash!.balanceCents, 100000 - 1299,
            reason: '支出 12.99 元后,现金余额应为 987.01 元');
      });

      test('收入增加余额(默认 1000 元 → 收入 500 元 → 1500 元)', () async {
        final salaryCategory = (await db.categoryDao.getAll())
            .firstWhere((c) => c.name == '工资');

        await db.transactionDao.insertTransaction(
          TransactionsCompanion.insert(
            accountId: cashAccountId,
            categoryId: salaryCategory.id,
            type: TransactionType.income,
            amountCents: 50000,
          ),
        );

        final cash = await db.accountDao.getById(cashAccountId);
        expect(cash!.balanceCents, 100000 + 50000);
      });

      test('repayment 类型用 insertTransaction 抛 ArgumentError', () async {
        final mealCategory = (await db.categoryDao.getAll())
            .firstWhere((c) => c.name == '餐饮');

        expect(
          () => db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              accountId: cashAccountId,
              categoryId: mealCategory.id,
              type: TransactionType.repayment,
              amountCents: 1000,
            ),
          ),
          throwsArgumentError,
          reason: 'repayment 必须走 transferRepayment(双账户事务),不能用 insertTransaction',
        );
      });

      test('账户不存在 → SQLite 外键约束拒绝 INSERT(预期行为)', () async {
        final mealCategory = (await db.categoryDao.getAll())
            .firstWhere((c) => c.name == '餐饮');

        // 故意用一个不存在的 accountId(99),SQLite FK 约束会拒绝 INSERT
        expect(
          () => db.transactionDao.insertTransaction(
            TransactionsCompanion.insert(
              accountId: 99, // 不存在 → 外键约束失败
              categoryId: mealCategory.id,
              type: TransactionType.expense,
              amountCents: 100,
            ),
          ),
          throwsA(isA<Exception>()),
          reason: '外键约束拒绝非法 accountId,这是 SQLite 层保护',
        );

        // 现金账户余额不变
        final cash = await db.accountDao.getById(cashAccountId);
        expect(cash!.balanceCents, 100000);
        // 无 transaction 写入
        final allTx = await db.select(db.transactions).get();
        expect(allTx, isEmpty);
      });
    });

    // ────────────────────────────────────────────────────────────────
    // 2. transferRepayment 完整路径
    // ────────────────────────────────────────────────────────────────

    group('transferRepayment 双账户事务', () {
      test('成功路径:储蓄 -500 + 信用卡已用 -500 + 写 repayment transaction', () async {
        final repaymentTxId = await db.transactionDao.transferRepayment(
          fromAccountId: cashAccountId,
          toAccountId: creditCardAccountId,
          amountCents: 50000, // 500 元
        );

        // 储蓄账户余额:1000 - 500 = 500 元
        final cash = await db.accountDao.getById(cashAccountId);
        expect(cash!.balanceCents, 100000 - 50000);

        // 信用卡已用额度:0 - 500 = -500(允许为负,极端情况)
        // 实际上 0 - 500 = -500,这种情况表示「信用卡被过度还款」— 允许
        final card = await db.accountDao.getById(creditCardAccountId);
        expect(card!.balanceCents, 0 - 50000);

        // 写入了 1 条 repayment transaction
        final tx = await db.transactionDao.getById(repaymentTxId);
        expect(tx, isNotNull);
        expect(tx!.type, TransactionType.repayment);
        expect(tx.amountCents, 50000);
        expect(tx.accountId, cashAccountId,
            reason: 'repayment 主账户 = 储蓄(扣款方)');
        expect(tx.note, '还招行信用卡');
      });

      test('储蓄余额不足 → StateError + 事务回滚(余额 + transaction 都不变)',
          () async {
        // 储蓄只有 1000 元,尝试还 5000 元
        await expectLater(
          db.transactionDao.transferRepayment(
            fromAccountId: cashAccountId,
            toAccountId: creditCardAccountId,
            amountCents: 500000,
          ),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('扣款账户余额不足'),
          )),
        );

        // 储蓄余额不变
        final cash = await db.accountDao.getById(cashAccountId);
        expect(cash!.balanceCents, 100000);
        // 信用卡已用不变
        final card = await db.accountDao.getById(creditCardAccountId);
        expect(card!.balanceCents, 0);
        // 无 transaction
        final allTx = await db.select(db.transactions).get();
        expect(allTx, isEmpty,
            reason: '事务回滚,repayment transaction 不应写入');
      });

      test('收款账户不存在 → StateError', () async {
        await expectLater(
          db.transactionDao.transferRepayment(
            fromAccountId: cashAccountId,
            toAccountId: 999, // 不存在
            amountCents: 1000,
          ),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('收款账户不存在'),
          )),
        );
      });

      test('扣款账户不存在 → StateError', () async {
        await expectLater(
          db.transactionDao.transferRepayment(
            fromAccountId: 999, // 不存在
            toAccountId: creditCardAccountId,
            amountCents: 1000,
          ),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('扣款账户不存在'),
          )),
        );
      });

      test('目标账户不是信用卡类型 → StateError', () async {
        // 故意把现金账户作为还款目标
        await expectLater(
          db.transactionDao.transferRepayment(
            fromAccountId: cashAccountId,
            toAccountId: cashAccountId, // 现金账户不是信用卡
            amountCents: 1000,
          ),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('收款账户必须是信用卡/花呗/网贷'),
          )),
        );
      });

      test('amountCents <= 0 → ArgumentError', () async {
        expect(
          () => db.transactionDao.transferRepayment(
            fromAccountId: cashAccountId,
            toAccountId: creditCardAccountId,
            amountCents: 0,
          ),
          throwsArgumentError,
        );

        expect(
          () => db.transactionDao.transferRepayment(
            fromAccountId: cashAccountId,
            toAccountId: creditCardAccountId,
            amountCents: -100,
          ),
          throwsArgumentError,
        );
      });
    });

    // ────────────────────────────────────────────────────────────────
    // 3. _getOrCreateRepaymentCategoryId(自动 seed)
    // ────────────────────────────────────────────────────────────────

    group('还款分类自动 seed', () {
      test('首次还款后自动创建「还款」分类,后续还款复用同一分类', () async {
        // 首次还款前,无「还款」分类
        final beforeCategories = await db.categoryDao.getAll();
        expect(beforeCategories.any((c) => c.name == '还款'), isFalse);

        // 首次还款
        await db.transactionDao.transferRepayment(
          fromAccountId: cashAccountId,
          toAccountId: creditCardAccountId,
          amountCents: 1000,
        );

        // 自动创建了「还款」分类
        final afterCategories = await db.categoryDao.getAll();
        final repayment = afterCategories.where((c) => c.name == '还款');
        expect(repayment, hasLength(1),
            reason: '首次还款自动 seed 1 条「还款」分类');
        expect(repayment.first.iconName, '💳');
        expect(repayment.first.type, TransactionType.expense);

        // 第二次还款,不应该再创建新分类
        await db.transactionDao.transferRepayment(
          fromAccountId: cashAccountId,
          toAccountId: creditCardAccountId,
          amountCents: 500,
        );

        final finalCategories = await db.categoryDao.getAll();
        expect(finalCategories.where((c) => c.name == '还款'), hasLength(1),
            reason: '后续还款复用同一「还款」分类');
      });

      test('用户已有「还款」分类 → transferRepayment 复用,不创建', () async {
        // 手动先创建一个「还款」分类
        await db.categoryDao.insertCategory(
          CategoriesCompanion.insert(
            name: '还款',
            iconName: '💳',
            colorValue: 4286470082,
            type: TransactionType.expense,
          ),
        );

        await db.transactionDao.transferRepayment(
          fromAccountId: cashAccountId,
          toAccountId: creditCardAccountId,
          amountCents: 1000,
        );

        final categories = await db.categoryDao.getAll();
        expect(categories.where((c) => c.name == '还款'), hasLength(1),
            reason: '用户已有「还款」分类,transferRepayment 复用,不创建新的');
      });
    });
  });
}