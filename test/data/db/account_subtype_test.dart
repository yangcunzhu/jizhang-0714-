// AccountCategory / AccountSubType 枚举单元测试(Stage 3 — ADR-0026)。
//
// 验证 5 大类 × 23 子类的:分组 / 大类归属 / 资产负债判定 / 向下兼容映射。

import 'package:flutter_test/flutter_test.dart';
import 'package:jizhang_app/data/db/tables/accounts.dart';

void main() {
  group('AccountCategory / AccountSubType(ADR-0026 5 大类 × 23 子类)', () {
    test('共 23 个子类', () {
      expect(AccountSubType.values.length, 23);
    });

    test('5 大类分组数量正确(资金5/信用7/充值3/理财6/借贷2)', () {
      expect(AccountCategory.fund.subTypes.length, 5);
      expect(AccountCategory.credit.subTypes.length, 7);
      expect(AccountCategory.recharge.subTypes.length, 3);
      expect(AccountCategory.investment.subTypes.length, 6);
      expect(AccountCategory.loan.subTypes.length, 2);
    });

    test('每个子类都能归到唯一大类(subTypes 覆盖全部,无遗漏)', () {
      final grouped =
          AccountCategory.values.expand((c) => c.subTypes).toSet();
      expect(grouped, AccountSubType.values.toSet());
    });

    test('资产/负债判定:信用类 + 借入 = 负债,其余 = 资产', () {
      // 信用类全部负债
      for (final s in AccountCategory.credit.subTypes) {
        expect(s.isLiability, isTrue, reason: '${s.name} 应为负债');
      }
      // 借入负债,借出资产
      expect(AccountSubType.borrowIn.isLiability, isTrue);
      expect(AccountSubType.lendOut.isLiability, isFalse);
      // 资金/充值/理财资产
      for (final s in [
        ...AccountCategory.fund.subTypes,
        ...AccountCategory.recharge.subTypes,
        ...AccountCategory.investment.subTypes,
      ]) {
        expect(s.isLiability, isFalse, reason: '${s.name} 应为资产');
      }
    });

    test('isCreditLike:仅信用大类为 true', () {
      for (final s in AccountSubType.values) {
        expect(s.isCreditLike, s.category == AccountCategory.credit);
      }
    });

    test('legacyType 向下兼容映射', () {
      expect(AccountSubType.cash.legacyType, AccountType.cash);
      expect(AccountSubType.savingsCard.legacyType, AccountType.savings);
      expect(AccountSubType.wechat.legacyType, AccountType.savings);
      expect(AccountSubType.creditCard.legacyType, AccountType.creditCard);
      expect(AccountSubType.huabei.legacyType, AccountType.huabei);
      expect(AccountSubType.jiebei.legacyType, AccountType.onlineLoan);
      expect(AccountSubType.jdBaitiao.legacyType, AccountType.onlineLoan);
      expect(AccountSubType.mutualFund.legacyType, AccountType.investment);
      expect(AccountSubType.stock.legacyType, AccountType.investment);
      expect(AccountSubType.lendOut.legacyType, AccountType.savings);
      expect(AccountSubType.borrowIn.legacyType, AccountType.onlineLoan);
    });

    test('每个子类都有非空 displayName + emoji', () {
      for (final s in AccountSubType.values) {
        expect(s.displayName.trim(), isNotEmpty);
        expect(s.emoji.trim(), isNotEmpty);
      }
    });
  });
}
