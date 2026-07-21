import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jizhang_app/data/db/app_database.dart';
import 'package:jizhang_app/data/db/database_provider.dart';
import 'package:jizhang_app/data/db/tables/categories.dart';
import 'package:jizhang_app/features/record/application/record_form_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('RecordFormNotifier - 计算器式金额', () {
    test('初始 amountCents = 0', () {
      expect(container.read(recordFormProvider).amountCents, 0);
    });

    test('appendDigit 整数累计：1234 cents', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(1);
      notifier.appendDigit(2);
      notifier.appendDigit(3);
      notifier.appendDigit(4);
      expect(container.read(recordFormProvider).amountCents, 1234);
    });

    test('appendDot + appendDigit 12.34 元 = 1234 cents', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(1);
      notifier.appendDigit(2);
      notifier.appendDot();
      notifier.appendDigit(3);
      notifier.appendDigit(4);
      expect(container.read(recordFormProvider).amountCents, 1234);
    });

    test('appendDot 幂等：第二次按忽略', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(5);
      notifier.appendDot();
      final first = container.read(recordFormProvider).amountCents;
      notifier.appendDot(); // 第二次
      expect(container.read(recordFormProvider).amountCents, first);
    });

    test('分位最多 2 位：1234 + .56 后再按 7 忽略', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(1);
      notifier.appendDigit(2);
      notifier.appendDot();
      notifier.appendDigit(5);
      notifier.appendDigit(6);
      notifier.appendDigit(7); // 应被忽略
      expect(container.read(recordFormProvider).amountCents, 1256);
    });

    test('backspace 删最后一位数字', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(1);
      notifier.appendDigit(2);
      notifier.appendDigit(3);
      notifier.backspace();
      expect(container.read(recordFormProvider).amountCents, 12);
    });

    test('backspace 删小数点回到整元', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(5);
      notifier.appendDot();
      notifier.appendDigit(3);
      notifier.backspace(); // 删 3
      notifier.backspace(); // 删小数点
      expect(container.read(recordFormProvider).amountCents, 5);
    });

    test('clearAmount 重置计算器状态', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.appendDigit(9);
      notifier.appendDot();
      notifier.appendDigit(9);
      notifier.clearAmount();
      expect(container.read(recordFormProvider).amountCents, 0);
      // 验证 _afterDot 也被清空：继续按 1 应进入整元阶段
      notifier.appendDigit(1);
      expect(container.read(recordFormProvider).amountCents, 1);
    });
  });

  group('RecordFormNotifier - 步骤导航', () {
    test('初始 step = selectCategory', () {
      expect(container.read(recordFormProvider).step, RecordStep.selectCategory);
    });

    test('selectCategory 选完分类后跳到 inputAmount', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(1);
      final s = container.read(recordFormProvider);
      expect(s.categoryId, 1);
      expect(s.step, RecordStep.inputAmount);
    });

    test('nextStep 未达条件时不变', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.nextStep(); // 无 categoryId
      expect(container.read(recordFormProvider).step, RecordStep.selectCategory);
    });

    test('nextStep 全流程推进', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(1);
      notifier.appendDigit(5); // amount > 0 才能推进
      notifier.nextStep();
      expect(container.read(recordFormProvider).step, RecordStep.selectAccount);
    });

    test('previousStep 在最前一步不变', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.previousStep();
      expect(container.read(recordFormProvider).step, RecordStep.selectCategory);
    });

    test('previousStep 回到上一步', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(1);
      notifier.appendDigit(5);
      notifier.nextStep();
      notifier.previousStep();
      expect(container.read(recordFormProvider).step, RecordStep.inputAmount);
    });
  });

  group('RecordFormNotifier - 保存', () {
    test('canSubmit 在金额=0 或账户=null 时为 false', () {
      final notifier = container.read(recordFormProvider.notifier);
      expect(container.read(recordFormProvider).canSubmit, false);
      notifier.appendDigit(1);
      expect(container.read(recordFormProvider).canSubmit, false);
      notifier.setAccount(1);
      expect(container.read(recordFormProvider).canSubmit, true);
    });

    test('submit 表单不完整抛 StateError', () async {
      final notifier = container.read(recordFormProvider.notifier);
      await expectLater(notifier.submit(), throwsStateError);
    });

    test('submit 完整表单 → 数据库插入一行', () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();

      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(cats.first.id);
      notifier.appendDigit(2);
      notifier.appendDigit(5);
      notifier.setAccount(acc!.id);
      notifier.setNote('咖啡');

      final id = await notifier.submit();
      expect(id, greaterThan(0));

      final list = await db.transactionDao.getAll();
      expect(list, hasLength(1));
      expect(list.first.amountCents, 25);
      expect(list.first.categoryId, cats.first.id);
      expect(list.first.accountId, acc.id);
      expect(list.first.note, '咖啡');
      // 分类是支出，提交的交易 type 也应是支出
      expect(list.first.type, cats.first.type);
      expect(list.first.type, TransactionType.expense);
    });

    test('submit 收入分类 → 交易 type = income', () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final incomeCat = cats.firstWhere((c) => c.type == TransactionType.income);

      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(incomeCat.id);
      notifier.appendDigit(5);
      notifier.appendDigit(0);
      notifier.appendDigit(0);
      notifier.appendDigit(0);
      notifier.setAccount(acc!.id);
      await notifier.submit();

      final list = await db.transactionDao.getAll();
      expect(list, hasLength(1));
      expect(list.first.amountCents, 5000);
      expect(list.first.type, TransactionType.income);
    });

    test('submit 后 state.isSubmitting 回到 false', () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(cats.first.id);
      notifier.appendDigit(1);
      notifier.setAccount(acc!.id);
      await notifier.submit();
      expect(container.read(recordFormProvider).isSubmitting, false);
    });
  });

  group('RecordFormNotifier - 重置', () {
    test('reset 清空所有状态 + 计算器内部标记', () {
      final notifier = container.read(recordFormProvider.notifier);
      notifier.selectCategory(5);
      notifier.appendDigit(9);
      notifier.appendDot();
      notifier.appendDigit(9);
      notifier.setNote('test');
      notifier.setAccount(7);

      notifier.reset();
      final s = container.read(recordFormProvider);
      expect(s.categoryId, null);
      expect(s.amountCents, 0);
      expect(s.note, '');
      expect(s.accountId, null);
      expect(s.step, RecordStep.selectCategory);

      // 验证 _afterDot 也被重置：appendDigit 后应是整元阶段
      notifier.appendDigit(1);
      expect(container.read(recordFormProvider).amountCents, 1);
    });
  });

  // ===== Day 8: 编辑 / 删除 / 退款 =====

  group('RecordFormNotifier - 编辑(loadForEdit)', () {
    test('isEditing 初始为 false', () {
      expect(container.read(recordFormProvider).isEditing, false);
      expect(container.read(recordFormProvider).editingTransactionId, null);
    });

    test('loadForEdit 反向填充 categoryId / amountCents / accountId / note',
        () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 5678,
          type: TransactionType.expense,
          categoryId: cats[3].id,
          accountId: acc!.id,
          note: const Value('Switch 游戏'),
        ),
      );
      final tx = (await db.transactionDao.getById(id))!;

      final notifier = container.read(recordFormProvider.notifier);
      notifier.loadForEdit(tx);

      final s = container.read(recordFormProvider);
      expect(s.editingTransactionId, id);
      expect(s.isEditing, true);
      expect(s.categoryId, cats[3].id);
      expect(s.amountCents, 5678);
      expect(s.accountId, acc.id);
      expect(s.note, 'Switch 游戏');
      expect(s.step, RecordStep.selectAccount);
    });

    test('loadForEdit 后 reset 清空 editingTransactionId', () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 100,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: acc!.id,
        ),
      );
      final tx = (await db.transactionDao.getById(id))!;
      final notifier = container.read(recordFormProvider.notifier);
      notifier.loadForEdit(tx);
      notifier.reset();
      expect(container.read(recordFormProvider).isEditing, false);
    });
  });

  group('RecordFormNotifier - 编辑模式 submit()', () {
    test('编辑模式 submit → UPDATE 现有交易,数据库仍 1 行 + 内容更新',
        () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 100,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: acc!.id,
          note: const Value('旧备注'),
        ),
      );
      final tx = (await db.transactionDao.getById(id))!;

      final notifier = container.read(recordFormProvider.notifier);
      notifier.loadForEdit(tx);
      notifier.clearAmount();
      notifier.appendDigit(2);
      notifier.appendDigit(0);
      notifier.appendDigit(0);
      notifier.setNote('新备注');

      final returnedId = await notifier.submit();
      expect(returnedId, id);

      final all = await db.transactionDao.getAll();
      expect(all, hasLength(1));
      expect(all.first.amountCents, 200);
      expect(all.first.note, '新备注');
      expect(all.first.id, id);
    });

    test('编辑模式 submit 找不到 id → 抛 StateError', () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final fake = TransactionEntry(
        id: 99999,
        amountCents: 100,
        type: TransactionType.expense,
        categoryId: cats.first.id,
        accountId: acc!.id,
        note: '',
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        excludeFromIncomeExpense: false,
        excludeFromBudget: false,
      );

      final notifier = container.read(recordFormProvider.notifier);
      notifier.loadForEdit(fake);
      notifier.setAccount(acc.id);
      await expectLater(notifier.submit(), throwsStateError);
    });
  });

  // D26 决策准备:删除 D9 submitAsRefund 测试(2026-08-08)。
  // D9 退款路径(反向插入 expense↔income)已退役,统一走 ADR-0030 的 refundMoney DAO。
  // D26 实施时(D26 commit)补 D26 refundMoney 测试,详 docs/daily/2026-08-09.md。

  group('RecordFormNotifier - 删除(deleteTransaction)', () {
    test('deleteTransaction 删除一行 + 返回 1', () async {
      final cats = await db.categoryDao.getAll();
      final acc = await db.accountDao.getDefault();
      final id = await db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amountCents: 100,
          type: TransactionType.expense,
          categoryId: cats.first.id,
          accountId: acc!.id,
        ),
      );

      final notifier = container.read(recordFormProvider.notifier);
      final rows = await notifier.deleteTransaction(id);

      expect(rows, 1);
      expect(await db.transactionDao.getById(id), isNull);
    });

    test('deleteTransaction 不存在的 id → 返回 0', () async {
      final notifier = container.read(recordFormProvider.notifier);
      final rows = await notifier.deleteTransaction(99999);
      expect(rows, 0);
    });
  });
}