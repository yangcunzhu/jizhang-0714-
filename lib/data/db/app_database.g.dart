// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($CategoriesTable.$convertertype);
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconName,
    colorValue,
    type,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      type: $CategoriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
}

class CategoryEntry extends DataClass implements Insertable<CategoryEntry> {
  final int id;

  /// 分类名称,1-20 字。
  final String name;

  /// 图标 = emoji 字符(UTF-16 字符串,如 '🍔' / '🚗'),UI 层用 Text 直接渲染。
  ///
  /// 决策:ADR-0019 — 不存 Material Icons codepoint。maxLength=40 足以放下 emoji 序列
  /// (带 ZWJ 组合如 👨‍👩‍👧‍👦 占 11 个 UTF-16 code unit)。
  final String iconName;

  /// 主题色,存 ARGB int(Color.value)。
  final int colorValue;

  /// 支出 / 收入。
  ///
  /// WHY: 用 textEnum(按枚举 name 字符串存储),而非 intEnum(按 index)。
  /// 这样未来在枚举中间插入新值(如 transfer)不会错位映射历史数据。
  final TransactionType type;

  /// 列表排序,越小越靠前。
  final int sortOrder;
  final DateTime createdAt;
  const CategoryEntry({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['icon_name'] = Variable<String>(iconName);
    map['color_value'] = Variable<int>(colorValue);
    {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type),
      );
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconName: Value(iconName),
      colorValue: Value(colorValue),
      type: Value(type),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      type: $CategoriesTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconName': serializer.toJson<String>(iconName),
      'colorValue': serializer.toJson<int>(colorValue),
      'type': serializer.toJson<String>(
        $CategoriesTable.$convertertype.toJson(type),
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryEntry copyWith({
    int? id,
    String? name,
    String? iconName,
    int? colorValue,
    TransactionType? type,
    int? sortOrder,
    DateTime? createdAt,
  }) => CategoryEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorValue: colorValue ?? this.colorValue,
    type: type ?? this.type,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryEntry copyWithCompanion(CategoriesCompanion data) {
    return CategoryEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      type: data.type.present ? data.type.value : this.type,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, iconName, colorValue, type, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.colorValue == this.colorValue &&
          other.type == this.type &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> iconName;
  final Value<int> colorValue;
  final Value<TransactionType> type;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconName,
    required int colorValue,
    required TransactionType type,
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       iconName = Value(iconName),
       colorValue = Value(colorValue),
       type = Value(type);
  static Insertable<CategoryEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? iconName,
    Expression<int>? colorValue,
    Expression<String>? type,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (colorValue != null) 'color_value': colorValue,
      if (type != null) 'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? iconName,
    Value<int>? colorValue,
    Value<TransactionType>? type,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $CategoriesTable.$convertertype.toSql(type.value),
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorValue: $colorValue, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceCentsMeta = const VerificationMeta(
    'balanceCents',
  );
  @override
  late final GeneratedColumn<int> balanceCents = GeneratedColumn<int>(
    'balance_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('cash'),
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<AccountSubType?, String> subType =
      GeneratedColumn<String>(
        'sub_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<AccountSubType?>($AccountsTable.$convertersubTypen);
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  @override
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _includeInNetWorthMeta = const VerificationMeta(
    'includeInNetWorth',
  );
  @override
  late final GeneratedColumn<bool> includeInNetWorth = GeneratedColumn<bool>(
    'include_in_net_worth',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_net_worth" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDefaultIncomeAccountMeta =
      const VerificationMeta('isDefaultIncomeAccount');
  @override
  late final GeneratedColumn<bool> isDefaultIncomeAccount =
      GeneratedColumn<bool>(
        'is_default_income_account',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_default_income_account" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _isDefaultExpenseAccountMeta =
      const VerificationMeta('isDefaultExpenseAccount');
  @override
  late final GeneratedColumn<bool> isDefaultExpenseAccount =
      GeneratedColumn<bool>(
        'is_default_expense_account',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_default_expense_account" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialDebtCentsMeta = const VerificationMeta(
    'initialDebtCents',
  );
  @override
  late final GeneratedColumn<int> initialDebtCents = GeneratedColumn<int>(
    'initial_debt_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billingDayMeta = const VerificationMeta(
    'billingDay',
  );
  @override
  late final GeneratedColumn<int> billingDay = GeneratedColumn<int>(
    'billing_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyNameMeta = const VerificationMeta(
    'counterpartyName',
  );
  @override
  late final GeneratedColumn<String> counterpartyName = GeneratedColumn<String>(
    'counterparty_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialLendBalanceCentsMeta =
      const VerificationMeta('initialLendBalanceCents');
  @override
  late final GeneratedColumn<int> initialLendBalanceCents =
      GeneratedColumn<int>(
        'initial_lend_balance_cents',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _initialTimeMeta = const VerificationMeta(
    'initialTime',
  );
  @override
  late final GeneratedColumn<DateTime> initialTime = GeneratedColumn<DateTime>(
    'initial_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lendCounterpartyNameMeta =
      const VerificationMeta('lendCounterpartyName');
  @override
  late final GeneratedColumn<String> lendCounterpartyName =
      GeneratedColumn<String>(
        'lend_counterparty_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lendDueDateMeta = const VerificationMeta(
    'lendDueDate',
  );
  @override
  late final GeneratedColumn<DateTime> lendDueDate = GeneratedColumn<DateTime>(
    'lend_due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    balanceCents,
    type,
    subType,
    brandName,
    includeInNetWorth,
    isPinned,
    isDefaultIncomeAccount,
    isDefaultExpenseAccount,
    creditLimit,
    initialDebtCents,
    billingDay,
    dueDay,
    startDate,
    dueDate,
    counterpartyName,
    initialLendBalanceCents,
    initialTime,
    lendCounterpartyName,
    lendDueDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('balance_cents')) {
      context.handle(
        _balanceCentsMeta,
        balanceCents.isAcceptableOrUnknown(
          data['balance_cents']!,
          _balanceCentsMeta,
        ),
      );
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    }
    if (data.containsKey('include_in_net_worth')) {
      context.handle(
        _includeInNetWorthMeta,
        includeInNetWorth.isAcceptableOrUnknown(
          data['include_in_net_worth']!,
          _includeInNetWorthMeta,
        ),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_default_income_account')) {
      context.handle(
        _isDefaultIncomeAccountMeta,
        isDefaultIncomeAccount.isAcceptableOrUnknown(
          data['is_default_income_account']!,
          _isDefaultIncomeAccountMeta,
        ),
      );
    }
    if (data.containsKey('is_default_expense_account')) {
      context.handle(
        _isDefaultExpenseAccountMeta,
        isDefaultExpenseAccount.isAcceptableOrUnknown(
          data['is_default_expense_account']!,
          _isDefaultExpenseAccountMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('initial_debt_cents')) {
      context.handle(
        _initialDebtCentsMeta,
        initialDebtCents.isAcceptableOrUnknown(
          data['initial_debt_cents']!,
          _initialDebtCentsMeta,
        ),
      );
    }
    if (data.containsKey('billing_day')) {
      context.handle(
        _billingDayMeta,
        billingDay.isAcceptableOrUnknown(data['billing_day']!, _billingDayMeta),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('counterparty_name')) {
      context.handle(
        _counterpartyNameMeta,
        counterpartyName.isAcceptableOrUnknown(
          data['counterparty_name']!,
          _counterpartyNameMeta,
        ),
      );
    }
    if (data.containsKey('initial_lend_balance_cents')) {
      context.handle(
        _initialLendBalanceCentsMeta,
        initialLendBalanceCents.isAcceptableOrUnknown(
          data['initial_lend_balance_cents']!,
          _initialLendBalanceCentsMeta,
        ),
      );
    }
    if (data.containsKey('initial_time')) {
      context.handle(
        _initialTimeMeta,
        initialTime.isAcceptableOrUnknown(
          data['initial_time']!,
          _initialTimeMeta,
        ),
      );
    }
    if (data.containsKey('lend_counterparty_name')) {
      context.handle(
        _lendCounterpartyNameMeta,
        lendCounterpartyName.isAcceptableOrUnknown(
          data['lend_counterparty_name']!,
          _lendCounterpartyNameMeta,
        ),
      );
    }
    if (data.containsKey('lend_due_date')) {
      context.handle(
        _lendDueDateMeta,
        lendDueDate.isAcceptableOrUnknown(
          data['lend_due_date']!,
          _lendDueDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      balanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_cents'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      subType: $AccountsTable.$convertersubTypen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sub_type'],
        ),
      ),
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      ),
      includeInNetWorth: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_net_worth'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isDefaultIncomeAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_income_account'],
      )!,
      isDefaultExpenseAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default_expense_account'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit'],
      ),
      initialDebtCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_debt_cents'],
      ),
      billingDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}billing_day'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      counterpartyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty_name'],
      ),
      initialLendBalanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}initial_lend_balance_cents'],
      ),
      initialTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}initial_time'],
      ),
      lendCounterpartyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lend_counterparty_name'],
      ),
      lendDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lend_due_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
  static JsonTypeConverter2<AccountSubType, String, String> $convertersubType =
      const EnumNameConverter<AccountSubType>(AccountSubType.values);
  static JsonTypeConverter2<AccountSubType?, String?, String?>
  $convertersubTypen = JsonTypeConverter2.asNullable($convertersubType);
}

class AccountEntry extends DataClass implements Insertable<AccountEntry> {
  final int id;

  /// 账户名称,1-20 字。
  final String name;

  /// 账户余额,单位:分(整数)。
  ///
  /// WHY: 金额一律用整数分存储,杜绝 double 浮点误差(0.1+0.2 问题)。
  final int balanceCents;

  /// 账户类型 — 向下兼容旧 6 种(v6 起由 subType 派生,见 [AccountSubType.legacyType])。
  final AccountType type;

  /// 账户子类型(v6 主模型,23 子类)。Nullable:v5 老数据 migration 回填。
  final AccountSubType? subType;

  /// 品牌/机构名(自定义子类用户填,如自定义银行名)。Nullable。
  final String? brandName;

  /// 是否计入净资产。
  final bool includeInNetWorth;

  /// 特别关注账户 — 资产列表置顶(ADR-0026 §9)。
  final bool isPinned;

  /// 默认收账账户 — 收入未指定账户时自动关联(ADR-0026 §9)。
  final bool isDefaultIncomeAccount;

  /// 默认支出账户 — 支出未指定账户时自动关联(ADR-0026 §9)。
  final bool isDefaultExpenseAccount;

  /// 信用额度(分)。仅信用类账户有意义。
  final int? creditLimit;

  /// 起始欠款(分)。信用类账户初始欠多少(ADR-0026 §11)。Nullable。
  final int? initialDebtCents;

  /// 出账日/账单日(1-31)。仅信用类账户有意义。
  final int? billingDay;

  /// 还款日(1-31)。仅信用类账户有意义。
  final int? dueDay;

  /// 起始时间 — 信用账户开始用卡时间 / 借贷借出借入日期(ADR-0026 §11/§12)。Nullable。
  final DateTime? startDate;

  /// 到期还款日期 — 借贷账户专用(具体日期,非月度 dueDay)。Nullable。
  final DateTime? dueDate;

  /// 借款人姓名 — 借贷账户专用(借给谁/从谁借)。Nullable。占位符规则见 CLAUDE §5。
  final String? counterpartyName;

  /// 起始余额/起始欠款(借贷账户专用,v8 D25 ADR-0029 加)。
  ///
  /// 借出 = 起始余额;借入 = 起始欠款。不在 includeInNetWorth 公式里
  /// (沿用 ADR-0026 §6/§8 D22 修订)。整数分存储,与项目其他 cents 字段一致
  /// (修正 ADR-0029 §决策 2 字面写的 RealColumn)。
  final int? initialLendBalanceCents;

  /// 借贷账户起始时间(UI 必填,DB nullable,v8 D25 ADR-0029 加)。
  ///
  /// UI 层(LendRecordPage/BorrowRecordPage)校验必填 + 语义「该时间之前的记录不
  /// 计入余额统计」。DB 层 nullable 让 v7 老数据零影响迁移。
  final DateTime? initialTime;

  /// 借贷账户对手方姓名(v8 D25 ADR-0029 加)。
  ///
  /// 与现有 [counterpartyName] 语义重叠,保留为借贷专用字段,UI 不暴露
  /// (LendRecordPage/BorrowRecordPage 直接用 transaction.counterpartyName)。
  /// TODO(D26+):评估与 [counterpartyName] 合并。
  final String? lendCounterpartyName;

  /// 借贷账户到期还款/收款日期(v8 D25 ADR-0029 加)。
  ///
  /// 与现有 [dueDate] 语义重叠(都是借贷账户到期日),保留为借贷专用。
  /// TODO(D26+):评估与 [dueDate] 合并。
  final DateTime? lendDueDate;
  final DateTime createdAt;
  const AccountEntry({
    required this.id,
    required this.name,
    required this.balanceCents,
    required this.type,
    this.subType,
    this.brandName,
    required this.includeInNetWorth,
    required this.isPinned,
    required this.isDefaultIncomeAccount,
    required this.isDefaultExpenseAccount,
    this.creditLimit,
    this.initialDebtCents,
    this.billingDay,
    this.dueDay,
    this.startDate,
    this.dueDate,
    this.counterpartyName,
    this.initialLendBalanceCents,
    this.initialTime,
    this.lendCounterpartyName,
    this.lendDueDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['balance_cents'] = Variable<int>(balanceCents);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || subType != null) {
      map['sub_type'] = Variable<String>(
        $AccountsTable.$convertersubTypen.toSql(subType),
      );
    }
    if (!nullToAbsent || brandName != null) {
      map['brand_name'] = Variable<String>(brandName);
    }
    map['include_in_net_worth'] = Variable<bool>(includeInNetWorth);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_default_income_account'] = Variable<bool>(isDefaultIncomeAccount);
    map['is_default_expense_account'] = Variable<bool>(isDefaultExpenseAccount);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    if (!nullToAbsent || initialDebtCents != null) {
      map['initial_debt_cents'] = Variable<int>(initialDebtCents);
    }
    if (!nullToAbsent || billingDay != null) {
      map['billing_day'] = Variable<int>(billingDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || counterpartyName != null) {
      map['counterparty_name'] = Variable<String>(counterpartyName);
    }
    if (!nullToAbsent || initialLendBalanceCents != null) {
      map['initial_lend_balance_cents'] = Variable<int>(
        initialLendBalanceCents,
      );
    }
    if (!nullToAbsent || initialTime != null) {
      map['initial_time'] = Variable<DateTime>(initialTime);
    }
    if (!nullToAbsent || lendCounterpartyName != null) {
      map['lend_counterparty_name'] = Variable<String>(lendCounterpartyName);
    }
    if (!nullToAbsent || lendDueDate != null) {
      map['lend_due_date'] = Variable<DateTime>(lendDueDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      balanceCents: Value(balanceCents),
      type: Value(type),
      subType: subType == null && nullToAbsent
          ? const Value.absent()
          : Value(subType),
      brandName: brandName == null && nullToAbsent
          ? const Value.absent()
          : Value(brandName),
      includeInNetWorth: Value(includeInNetWorth),
      isPinned: Value(isPinned),
      isDefaultIncomeAccount: Value(isDefaultIncomeAccount),
      isDefaultExpenseAccount: Value(isDefaultExpenseAccount),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      initialDebtCents: initialDebtCents == null && nullToAbsent
          ? const Value.absent()
          : Value(initialDebtCents),
      billingDay: billingDay == null && nullToAbsent
          ? const Value.absent()
          : Value(billingDay),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      counterpartyName: counterpartyName == null && nullToAbsent
          ? const Value.absent()
          : Value(counterpartyName),
      initialLendBalanceCents: initialLendBalanceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(initialLendBalanceCents),
      initialTime: initialTime == null && nullToAbsent
          ? const Value.absent()
          : Value(initialTime),
      lendCounterpartyName: lendCounterpartyName == null && nullToAbsent
          ? const Value.absent()
          : Value(lendCounterpartyName),
      lendDueDate: lendDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lendDueDate),
      createdAt: Value(createdAt),
    );
  }

  factory AccountEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountEntry(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      balanceCents: serializer.fromJson<int>(json['balanceCents']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      subType: $AccountsTable.$convertersubTypen.fromJson(
        serializer.fromJson<String?>(json['subType']),
      ),
      brandName: serializer.fromJson<String?>(json['brandName']),
      includeInNetWorth: serializer.fromJson<bool>(json['includeInNetWorth']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isDefaultIncomeAccount: serializer.fromJson<bool>(
        json['isDefaultIncomeAccount'],
      ),
      isDefaultExpenseAccount: serializer.fromJson<bool>(
        json['isDefaultExpenseAccount'],
      ),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      initialDebtCents: serializer.fromJson<int?>(json['initialDebtCents']),
      billingDay: serializer.fromJson<int?>(json['billingDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      counterpartyName: serializer.fromJson<String?>(json['counterpartyName']),
      initialLendBalanceCents: serializer.fromJson<int?>(
        json['initialLendBalanceCents'],
      ),
      initialTime: serializer.fromJson<DateTime?>(json['initialTime']),
      lendCounterpartyName: serializer.fromJson<String?>(
        json['lendCounterpartyName'],
      ),
      lendDueDate: serializer.fromJson<DateTime?>(json['lendDueDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'balanceCents': serializer.toJson<int>(balanceCents),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'subType': serializer.toJson<String?>(
        $AccountsTable.$convertersubTypen.toJson(subType),
      ),
      'brandName': serializer.toJson<String?>(brandName),
      'includeInNetWorth': serializer.toJson<bool>(includeInNetWorth),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isDefaultIncomeAccount': serializer.toJson<bool>(isDefaultIncomeAccount),
      'isDefaultExpenseAccount': serializer.toJson<bool>(
        isDefaultExpenseAccount,
      ),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'initialDebtCents': serializer.toJson<int?>(initialDebtCents),
      'billingDay': serializer.toJson<int?>(billingDay),
      'dueDay': serializer.toJson<int?>(dueDay),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'counterpartyName': serializer.toJson<String?>(counterpartyName),
      'initialLendBalanceCents': serializer.toJson<int?>(
        initialLendBalanceCents,
      ),
      'initialTime': serializer.toJson<DateTime?>(initialTime),
      'lendCounterpartyName': serializer.toJson<String?>(lendCounterpartyName),
      'lendDueDate': serializer.toJson<DateTime?>(lendDueDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AccountEntry copyWith({
    int? id,
    String? name,
    int? balanceCents,
    AccountType? type,
    Value<AccountSubType?> subType = const Value.absent(),
    Value<String?> brandName = const Value.absent(),
    bool? includeInNetWorth,
    bool? isPinned,
    bool? isDefaultIncomeAccount,
    bool? isDefaultExpenseAccount,
    Value<int?> creditLimit = const Value.absent(),
    Value<int?> initialDebtCents = const Value.absent(),
    Value<int?> billingDay = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<String?> counterpartyName = const Value.absent(),
    Value<int?> initialLendBalanceCents = const Value.absent(),
    Value<DateTime?> initialTime = const Value.absent(),
    Value<String?> lendCounterpartyName = const Value.absent(),
    Value<DateTime?> lendDueDate = const Value.absent(),
    DateTime? createdAt,
  }) => AccountEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    balanceCents: balanceCents ?? this.balanceCents,
    type: type ?? this.type,
    subType: subType.present ? subType.value : this.subType,
    brandName: brandName.present ? brandName.value : this.brandName,
    includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
    isPinned: isPinned ?? this.isPinned,
    isDefaultIncomeAccount:
        isDefaultIncomeAccount ?? this.isDefaultIncomeAccount,
    isDefaultExpenseAccount:
        isDefaultExpenseAccount ?? this.isDefaultExpenseAccount,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    initialDebtCents: initialDebtCents.present
        ? initialDebtCents.value
        : this.initialDebtCents,
    billingDay: billingDay.present ? billingDay.value : this.billingDay,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    startDate: startDate.present ? startDate.value : this.startDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    counterpartyName: counterpartyName.present
        ? counterpartyName.value
        : this.counterpartyName,
    initialLendBalanceCents: initialLendBalanceCents.present
        ? initialLendBalanceCents.value
        : this.initialLendBalanceCents,
    initialTime: initialTime.present ? initialTime.value : this.initialTime,
    lendCounterpartyName: lendCounterpartyName.present
        ? lendCounterpartyName.value
        : this.lendCounterpartyName,
    lendDueDate: lendDueDate.present ? lendDueDate.value : this.lendDueDate,
    createdAt: createdAt ?? this.createdAt,
  );
  AccountEntry copyWithCompanion(AccountsCompanion data) {
    return AccountEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      balanceCents: data.balanceCents.present
          ? data.balanceCents.value
          : this.balanceCents,
      type: data.type.present ? data.type.value : this.type,
      subType: data.subType.present ? data.subType.value : this.subType,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      includeInNetWorth: data.includeInNetWorth.present
          ? data.includeInNetWorth.value
          : this.includeInNetWorth,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isDefaultIncomeAccount: data.isDefaultIncomeAccount.present
          ? data.isDefaultIncomeAccount.value
          : this.isDefaultIncomeAccount,
      isDefaultExpenseAccount: data.isDefaultExpenseAccount.present
          ? data.isDefaultExpenseAccount.value
          : this.isDefaultExpenseAccount,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      initialDebtCents: data.initialDebtCents.present
          ? data.initialDebtCents.value
          : this.initialDebtCents,
      billingDay: data.billingDay.present
          ? data.billingDay.value
          : this.billingDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      counterpartyName: data.counterpartyName.present
          ? data.counterpartyName.value
          : this.counterpartyName,
      initialLendBalanceCents: data.initialLendBalanceCents.present
          ? data.initialLendBalanceCents.value
          : this.initialLendBalanceCents,
      initialTime: data.initialTime.present
          ? data.initialTime.value
          : this.initialTime,
      lendCounterpartyName: data.lendCounterpartyName.present
          ? data.lendCounterpartyName.value
          : this.lendCounterpartyName,
      lendDueDate: data.lendDueDate.present
          ? data.lendDueDate.value
          : this.lendDueDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balanceCents: $balanceCents, ')
          ..write('type: $type, ')
          ..write('subType: $subType, ')
          ..write('brandName: $brandName, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('isPinned: $isPinned, ')
          ..write('isDefaultIncomeAccount: $isDefaultIncomeAccount, ')
          ..write('isDefaultExpenseAccount: $isDefaultExpenseAccount, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('initialDebtCents: $initialDebtCents, ')
          ..write('billingDay: $billingDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('initialLendBalanceCents: $initialLendBalanceCents, ')
          ..write('initialTime: $initialTime, ')
          ..write('lendCounterpartyName: $lendCounterpartyName, ')
          ..write('lendDueDate: $lendDueDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    balanceCents,
    type,
    subType,
    brandName,
    includeInNetWorth,
    isPinned,
    isDefaultIncomeAccount,
    isDefaultExpenseAccount,
    creditLimit,
    initialDebtCents,
    billingDay,
    dueDay,
    startDate,
    dueDate,
    counterpartyName,
    initialLendBalanceCents,
    initialTime,
    lendCounterpartyName,
    lendDueDate,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.balanceCents == this.balanceCents &&
          other.type == this.type &&
          other.subType == this.subType &&
          other.brandName == this.brandName &&
          other.includeInNetWorth == this.includeInNetWorth &&
          other.isPinned == this.isPinned &&
          other.isDefaultIncomeAccount == this.isDefaultIncomeAccount &&
          other.isDefaultExpenseAccount == this.isDefaultExpenseAccount &&
          other.creditLimit == this.creditLimit &&
          other.initialDebtCents == this.initialDebtCents &&
          other.billingDay == this.billingDay &&
          other.dueDay == this.dueDay &&
          other.startDate == this.startDate &&
          other.dueDate == this.dueDate &&
          other.counterpartyName == this.counterpartyName &&
          other.initialLendBalanceCents == this.initialLendBalanceCents &&
          other.initialTime == this.initialTime &&
          other.lendCounterpartyName == this.lendCounterpartyName &&
          other.lendDueDate == this.lendDueDate &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<AccountEntry> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> balanceCents;
  final Value<AccountType> type;
  final Value<AccountSubType?> subType;
  final Value<String?> brandName;
  final Value<bool> includeInNetWorth;
  final Value<bool> isPinned;
  final Value<bool> isDefaultIncomeAccount;
  final Value<bool> isDefaultExpenseAccount;
  final Value<int?> creditLimit;
  final Value<int?> initialDebtCents;
  final Value<int?> billingDay;
  final Value<int?> dueDay;
  final Value<DateTime?> startDate;
  final Value<DateTime?> dueDate;
  final Value<String?> counterpartyName;
  final Value<int?> initialLendBalanceCents;
  final Value<DateTime?> initialTime;
  final Value<String?> lendCounterpartyName;
  final Value<DateTime?> lendDueDate;
  final Value<DateTime> createdAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.balanceCents = const Value.absent(),
    this.type = const Value.absent(),
    this.subType = const Value.absent(),
    this.brandName = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isDefaultIncomeAccount = const Value.absent(),
    this.isDefaultExpenseAccount = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.initialDebtCents = const Value.absent(),
    this.billingDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.initialLendBalanceCents = const Value.absent(),
    this.initialTime = const Value.absent(),
    this.lendCounterpartyName = const Value.absent(),
    this.lendDueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.balanceCents = const Value.absent(),
    this.type = const Value.absent(),
    this.subType = const Value.absent(),
    this.brandName = const Value.absent(),
    this.includeInNetWorth = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isDefaultIncomeAccount = const Value.absent(),
    this.isDefaultExpenseAccount = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.initialDebtCents = const Value.absent(),
    this.billingDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.startDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.initialLendBalanceCents = const Value.absent(),
    this.initialTime = const Value.absent(),
    this.lendCounterpartyName = const Value.absent(),
    this.lendDueDate = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<AccountEntry> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? balanceCents,
    Expression<String>? type,
    Expression<String>? subType,
    Expression<String>? brandName,
    Expression<bool>? includeInNetWorth,
    Expression<bool>? isPinned,
    Expression<bool>? isDefaultIncomeAccount,
    Expression<bool>? isDefaultExpenseAccount,
    Expression<int>? creditLimit,
    Expression<int>? initialDebtCents,
    Expression<int>? billingDay,
    Expression<int>? dueDay,
    Expression<DateTime>? startDate,
    Expression<DateTime>? dueDate,
    Expression<String>? counterpartyName,
    Expression<int>? initialLendBalanceCents,
    Expression<DateTime>? initialTime,
    Expression<String>? lendCounterpartyName,
    Expression<DateTime>? lendDueDate,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (balanceCents != null) 'balance_cents': balanceCents,
      if (type != null) 'type': type,
      if (subType != null) 'sub_type': subType,
      if (brandName != null) 'brand_name': brandName,
      if (includeInNetWorth != null) 'include_in_net_worth': includeInNetWorth,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isDefaultIncomeAccount != null)
        'is_default_income_account': isDefaultIncomeAccount,
      if (isDefaultExpenseAccount != null)
        'is_default_expense_account': isDefaultExpenseAccount,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (initialDebtCents != null) 'initial_debt_cents': initialDebtCents,
      if (billingDay != null) 'billing_day': billingDay,
      if (dueDay != null) 'due_day': dueDay,
      if (startDate != null) 'start_date': startDate,
      if (dueDate != null) 'due_date': dueDate,
      if (counterpartyName != null) 'counterparty_name': counterpartyName,
      if (initialLendBalanceCents != null)
        'initial_lend_balance_cents': initialLendBalanceCents,
      if (initialTime != null) 'initial_time': initialTime,
      if (lendCounterpartyName != null)
        'lend_counterparty_name': lendCounterpartyName,
      if (lendDueDate != null) 'lend_due_date': lendDueDate,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? balanceCents,
    Value<AccountType>? type,
    Value<AccountSubType?>? subType,
    Value<String?>? brandName,
    Value<bool>? includeInNetWorth,
    Value<bool>? isPinned,
    Value<bool>? isDefaultIncomeAccount,
    Value<bool>? isDefaultExpenseAccount,
    Value<int?>? creditLimit,
    Value<int?>? initialDebtCents,
    Value<int?>? billingDay,
    Value<int?>? dueDay,
    Value<DateTime?>? startDate,
    Value<DateTime?>? dueDate,
    Value<String?>? counterpartyName,
    Value<int?>? initialLendBalanceCents,
    Value<DateTime?>? initialTime,
    Value<String?>? lendCounterpartyName,
    Value<DateTime?>? lendDueDate,
    Value<DateTime>? createdAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      balanceCents: balanceCents ?? this.balanceCents,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      brandName: brandName ?? this.brandName,
      includeInNetWorth: includeInNetWorth ?? this.includeInNetWorth,
      isPinned: isPinned ?? this.isPinned,
      isDefaultIncomeAccount:
          isDefaultIncomeAccount ?? this.isDefaultIncomeAccount,
      isDefaultExpenseAccount:
          isDefaultExpenseAccount ?? this.isDefaultExpenseAccount,
      creditLimit: creditLimit ?? this.creditLimit,
      initialDebtCents: initialDebtCents ?? this.initialDebtCents,
      billingDay: billingDay ?? this.billingDay,
      dueDay: dueDay ?? this.dueDay,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      initialLendBalanceCents:
          initialLendBalanceCents ?? this.initialLendBalanceCents,
      initialTime: initialTime ?? this.initialTime,
      lendCounterpartyName: lendCounterpartyName ?? this.lendCounterpartyName,
      lendDueDate: lendDueDate ?? this.lendDueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (balanceCents.present) {
      map['balance_cents'] = Variable<int>(balanceCents.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (subType.present) {
      map['sub_type'] = Variable<String>(
        $AccountsTable.$convertersubTypen.toSql(subType.value),
      );
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (includeInNetWorth.present) {
      map['include_in_net_worth'] = Variable<bool>(includeInNetWorth.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isDefaultIncomeAccount.present) {
      map['is_default_income_account'] = Variable<bool>(
        isDefaultIncomeAccount.value,
      );
    }
    if (isDefaultExpenseAccount.present) {
      map['is_default_expense_account'] = Variable<bool>(
        isDefaultExpenseAccount.value,
      );
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (initialDebtCents.present) {
      map['initial_debt_cents'] = Variable<int>(initialDebtCents.value);
    }
    if (billingDay.present) {
      map['billing_day'] = Variable<int>(billingDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (counterpartyName.present) {
      map['counterparty_name'] = Variable<String>(counterpartyName.value);
    }
    if (initialLendBalanceCents.present) {
      map['initial_lend_balance_cents'] = Variable<int>(
        initialLendBalanceCents.value,
      );
    }
    if (initialTime.present) {
      map['initial_time'] = Variable<DateTime>(initialTime.value);
    }
    if (lendCounterpartyName.present) {
      map['lend_counterparty_name'] = Variable<String>(
        lendCounterpartyName.value,
      );
    }
    if (lendDueDate.present) {
      map['lend_due_date'] = Variable<DateTime>(lendDueDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('balanceCents: $balanceCents, ')
          ..write('type: $type, ')
          ..write('subType: $subType, ')
          ..write('brandName: $brandName, ')
          ..write('includeInNetWorth: $includeInNetWorth, ')
          ..write('isPinned: $isPinned, ')
          ..write('isDefaultIncomeAccount: $isDefaultIncomeAccount, ')
          ..write('isDefaultExpenseAccount: $isDefaultExpenseAccount, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('initialDebtCents: $initialDebtCents, ')
          ..write('billingDay: $billingDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('startDate: $startDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('initialLendBalanceCents: $initialLendBalanceCents, ')
          ..write('initialTime: $initialTime, ')
          ..write('lendCounterpartyName: $lendCounterpartyName, ')
          ..write('lendDueDate: $lendDueDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<TransactionType>($TransactionsTable.$convertertype);
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _installmentPeriodMeta = const VerificationMeta(
    'installmentPeriod',
  );
  @override
  late final GeneratedColumn<int> installmentPeriod = GeneratedColumn<int>(
    'installment_period',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<int> fromAccountId = GeneratedColumn<int>(
    'from_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyNameMeta = const VerificationMeta(
    'counterpartyName',
  );
  @override
  late final GeneratedColumn<String> counterpartyName = GeneratedColumn<String>(
    'counterparty_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lendStartDateMeta = const VerificationMeta(
    'lendStartDate',
  );
  @override
  late final GeneratedColumn<DateTime> lendStartDate =
      GeneratedColumn<DateTime>(
        'lend_start_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lendEndDateMeta = const VerificationMeta(
    'lendEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> lendEndDate = GeneratedColumn<DateTime>(
    'lend_end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalTransactionIdMeta =
      const VerificationMeta('originalTransactionId');
  @override
  late final GeneratedColumn<int> originalTransactionId = GeneratedColumn<int>(
    'original_transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundNoteMeta = const VerificationMeta(
    'refundNote',
  );
  @override
  late final GeneratedColumn<String> refundNote = GeneratedColumn<String>(
    'refund_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _excludeFromIncomeExpenseMeta =
      const VerificationMeta('excludeFromIncomeExpense');
  @override
  late final GeneratedColumn<bool> excludeFromIncomeExpense =
      GeneratedColumn<bool>(
        'exclude_from_income_expense',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("exclude_from_income_expense" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _excludeFromBudgetMeta = const VerificationMeta(
    'excludeFromBudget',
  );
  @override
  late final GeneratedColumn<bool> excludeFromBudget = GeneratedColumn<bool>(
    'exclude_from_budget',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exclude_from_budget" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    amountCents,
    type,
    categoryId,
    accountId,
    note,
    occurredAt,
    createdAt,
    updatedAt,
    installmentPeriod,
    fromAccountId,
    toAccountId,
    counterpartyName,
    startDate,
    lendStartDate,
    lendEndDate,
    originalTransactionId,
    refundNote,
    excludeFromIncomeExpense,
    excludeFromBudget,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('installment_period')) {
      context.handle(
        _installmentPeriodMeta,
        installmentPeriod.isAcceptableOrUnknown(
          data['installment_period']!,
          _installmentPeriodMeta,
        ),
      );
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('counterparty_name')) {
      context.handle(
        _counterpartyNameMeta,
        counterpartyName.isAcceptableOrUnknown(
          data['counterparty_name']!,
          _counterpartyNameMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('lend_start_date')) {
      context.handle(
        _lendStartDateMeta,
        lendStartDate.isAcceptableOrUnknown(
          data['lend_start_date']!,
          _lendStartDateMeta,
        ),
      );
    }
    if (data.containsKey('lend_end_date')) {
      context.handle(
        _lendEndDateMeta,
        lendEndDate.isAcceptableOrUnknown(
          data['lend_end_date']!,
          _lendEndDateMeta,
        ),
      );
    }
    if (data.containsKey('original_transaction_id')) {
      context.handle(
        _originalTransactionIdMeta,
        originalTransactionId.isAcceptableOrUnknown(
          data['original_transaction_id']!,
          _originalTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('refund_note')) {
      context.handle(
        _refundNoteMeta,
        refundNote.isAcceptableOrUnknown(data['refund_note']!, _refundNoteMeta),
      );
    }
    if (data.containsKey('exclude_from_income_expense')) {
      context.handle(
        _excludeFromIncomeExpenseMeta,
        excludeFromIncomeExpense.isAcceptableOrUnknown(
          data['exclude_from_income_expense']!,
          _excludeFromIncomeExpenseMeta,
        ),
      );
    }
    if (data.containsKey('exclude_from_budget')) {
      context.handle(
        _excludeFromBudgetMeta,
        excludeFromBudget.isAcceptableOrUnknown(
          data['exclude_from_budget']!,
          _excludeFromBudgetMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      type: $TransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      installmentPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_period'],
      ),
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      counterpartyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty_name'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      lendStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lend_start_date'],
      ),
      lendEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lend_end_date'],
      ),
      originalTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_transaction_id'],
      ),
      refundNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refund_note'],
      ),
      excludeFromIncomeExpense: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_income_expense'],
      )!,
      excludeFromBudget: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exclude_from_budget'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, String, String> $convertertype =
      const EnumNameConverter<TransactionType>(TransactionType.values);
}

class TransactionEntry extends DataClass
    implements Insertable<TransactionEntry> {
  final int id;

  /// 金额,单位:分(整数,恒 > 0)。支出 / 收入由 [type] 区分,不用负数。
  ///
  /// 非负由表级 CHECK 约束强制(见 [customConstraints]),拦截 UI/迁移 bug。
  final int amountCents;

  /// 支出 / 收入 / 还款。textEnum 按 name 存储(见 Categories.type 说明)。
  ///
  /// WHY: textEnum 加新枚举值(如 S03 加 `repayment`)无需 ALTER TABLE,SQLite 列定义不变,
  /// 仅 Dart 层 enum 多一个常量,迁移成本零。决策见 ADR-0017 + ADR-0021。
  final TransactionType type;

  /// 所属分类。
  final int categoryId;

  /// 所属账户。
  final int accountId;

  /// 备注,可空(默认空串)。
  final String note;

  /// 交易发生时间(用户可改),默认当前。列表按此倒序。
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 还款期数(S03 D20 + ADR-0024 增)。
  ///
  /// 仅网贷还款(type=repayment + toAccountId=网贷账户)有意义。
  /// 普通还款(信用卡 / 花呗)为 null。Nullable 让现有数据无需 backfill。
  ///
  /// WHY: 网贷有「12 期 / 24 期 / 36 期」概念,记账流水需要记录,下游 S05 净资产
  /// / S07 AI 攒攒会基于此判断还款提醒是否值得。
  final int? installmentPeriod;

  /// 扣款方账户 ID(v7 D22 + ADR-0026 借贷/转账增)。
  ///
  /// 用于 `transfer` / `lend`(资金方) / `repayment`(扣款方)。普通 expense/income 用
  /// 主 [accountId] 即可,本字段 nullable 让现有数据无需 backfill。
  ///
  /// 外键策略:**不显式 references(Accounts, ...)** —— 避免 drift codegen 在 nullable
  /// + FK 上出现「NOT NULL constraint failed」的迁移陷阱。FK 完整性由调用方保证
  /// (DAO 的事务里先 insert 再 update)。
  final int? fromAccountId;

  /// 入款方账户 ID(v7 D22 + ADR-0026 借贷/转账/还款增)。
  ///
  /// 用于 `transfer`(入款)/ `borrow`(借入方)/ `repayment`(欠款方)/ `lend`(借出人)。
  /// Nullable 让现有数据无需 backfill。
  final int? toAccountId;

  /// 借款对手方姓名(v7 D22 + ADR-0026 借贷增)。
  ///
  /// 借出 = 借款人(借给谁);借入 = 出借人(从谁借)。Nullable。
  /// 存为冗余字段(账户表也有 counterpartyName,这里冗余便于 transaction 直接渲染)。
  final String? counterpartyName;

  /// 起始时间(借贷记账用,v7 D22 增)。
  ///
  /// 用户填借贷账户时输入的「起始时间」会作为该借贷 transaction 的 occurredAt,
  /// 实现咔皮「该时间之前的记录不计入余额统计」语义。
  final DateTime? startDate;

  /// 借出/借入 transaction 的起始日期(v8 D25 ADR-0029 加)。
  ///
  /// 与 [startDate] 语义重叠(都是借贷 transaction 的起始日期),保留为 ADR-0029
  /// §决策 3 字面字段名。DAO 暂用 [startDate],本字段留给 D26+ 评估合并。
  /// TODO(D26+):评估与 [startDate] 合并。
  final DateTime? lendStartDate;

  /// 借出 transaction 的收款日期 / 借入 transaction 的还款日期(v8 D25 ADR-0029 加)。
  ///
  /// 区别于 [lendDueDate](账户级到期日),本字段是 transaction 级应收/应付日期,
  /// 下游 S07 异常检测会基于此判断「应收未收」「到期未还」。Nullable。
  final DateTime? lendEndDate;

  /// 退款原 transaction ID(v8 D25 ADR-0030 占位)。
  ///
  /// 当 transaction.type='refund' 时,本字段指向被退款的原 transaction.id,
  /// 形成反向引用链。普通 expense/income/transfer/repayment/lend/borrow 为 null。
  /// 不显式 references(Transactions, ...)避免 drift codegen 在 nullable + FK 上
  /// 出现迁移陷阱(沿用 fromAccountId 的策略)。
  final int? originalTransactionId;

  /// 退款备注(v8 D25 ADR-0030 占位)。
  final String? refundNote;

  /// 不计入收支统计(v8 D25 ADR-0033 占位)。
  ///
  /// 咔皮图 19/293 完美证实:某些转账(如内部调账、还款入账)需要隐藏掉,不显示
  /// 在月度收支柱状图。默认 false,余额永远更新(沿用 ADR-0022 策略)。
  final bool excludeFromIncomeExpense;

  /// 不计入预算(v8 D25 ADR-0033 占位)。
  ///
  /// 咔皮图 19/293:某些交易(如信用卡还款)实际不算支出,需要排除在分类预算外。
  /// 默认 false。
  final bool excludeFromBudget;
  const TransactionEntry({
    required this.id,
    required this.amountCents,
    required this.type,
    required this.categoryId,
    required this.accountId,
    required this.note,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.installmentPeriod,
    this.fromAccountId,
    this.toAccountId,
    this.counterpartyName,
    this.startDate,
    this.lendStartDate,
    this.lendEndDate,
    this.originalTransactionId,
    this.refundNote,
    required this.excludeFromIncomeExpense,
    required this.excludeFromBudget,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_cents'] = Variable<int>(amountCents);
    {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type),
      );
    }
    map['category_id'] = Variable<int>(categoryId);
    map['account_id'] = Variable<int>(accountId);
    map['note'] = Variable<String>(note);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || installmentPeriod != null) {
      map['installment_period'] = Variable<int>(installmentPeriod);
    }
    if (!nullToAbsent || fromAccountId != null) {
      map['from_account_id'] = Variable<int>(fromAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    if (!nullToAbsent || counterpartyName != null) {
      map['counterparty_name'] = Variable<String>(counterpartyName);
    }
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || lendStartDate != null) {
      map['lend_start_date'] = Variable<DateTime>(lendStartDate);
    }
    if (!nullToAbsent || lendEndDate != null) {
      map['lend_end_date'] = Variable<DateTime>(lendEndDate);
    }
    if (!nullToAbsent || originalTransactionId != null) {
      map['original_transaction_id'] = Variable<int>(originalTransactionId);
    }
    if (!nullToAbsent || refundNote != null) {
      map['refund_note'] = Variable<String>(refundNote);
    }
    map['exclude_from_income_expense'] = Variable<bool>(
      excludeFromIncomeExpense,
    );
    map['exclude_from_budget'] = Variable<bool>(excludeFromBudget);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amountCents: Value(amountCents),
      type: Value(type),
      categoryId: Value(categoryId),
      accountId: Value(accountId),
      note: Value(note),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      installmentPeriod: installmentPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(installmentPeriod),
      fromAccountId: fromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(fromAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      counterpartyName: counterpartyName == null && nullToAbsent
          ? const Value.absent()
          : Value(counterpartyName),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      lendStartDate: lendStartDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lendStartDate),
      lendEndDate: lendEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lendEndDate),
      originalTransactionId: originalTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTransactionId),
      refundNote: refundNote == null && nullToAbsent
          ? const Value.absent()
          : Value(refundNote),
      excludeFromIncomeExpense: Value(excludeFromIncomeExpense),
      excludeFromBudget: Value(excludeFromBudget),
    );
  }

  factory TransactionEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionEntry(
      id: serializer.fromJson<int>(json['id']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      type: $TransactionsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      note: serializer.fromJson<String>(json['note']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      installmentPeriod: serializer.fromJson<int?>(json['installmentPeriod']),
      fromAccountId: serializer.fromJson<int?>(json['fromAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      counterpartyName: serializer.fromJson<String?>(json['counterpartyName']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      lendStartDate: serializer.fromJson<DateTime?>(json['lendStartDate']),
      lendEndDate: serializer.fromJson<DateTime?>(json['lendEndDate']),
      originalTransactionId: serializer.fromJson<int?>(
        json['originalTransactionId'],
      ),
      refundNote: serializer.fromJson<String?>(json['refundNote']),
      excludeFromIncomeExpense: serializer.fromJson<bool>(
        json['excludeFromIncomeExpense'],
      ),
      excludeFromBudget: serializer.fromJson<bool>(json['excludeFromBudget']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountCents': serializer.toJson<int>(amountCents),
      'type': serializer.toJson<String>(
        $TransactionsTable.$convertertype.toJson(type),
      ),
      'categoryId': serializer.toJson<int>(categoryId),
      'accountId': serializer.toJson<int>(accountId),
      'note': serializer.toJson<String>(note),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'installmentPeriod': serializer.toJson<int?>(installmentPeriod),
      'fromAccountId': serializer.toJson<int?>(fromAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'counterpartyName': serializer.toJson<String?>(counterpartyName),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'lendStartDate': serializer.toJson<DateTime?>(lendStartDate),
      'lendEndDate': serializer.toJson<DateTime?>(lendEndDate),
      'originalTransactionId': serializer.toJson<int?>(originalTransactionId),
      'refundNote': serializer.toJson<String?>(refundNote),
      'excludeFromIncomeExpense': serializer.toJson<bool>(
        excludeFromIncomeExpense,
      ),
      'excludeFromBudget': serializer.toJson<bool>(excludeFromBudget),
    };
  }

  TransactionEntry copyWith({
    int? id,
    int? amountCents,
    TransactionType? type,
    int? categoryId,
    int? accountId,
    String? note,
    DateTime? occurredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<int?> installmentPeriod = const Value.absent(),
    Value<int?> fromAccountId = const Value.absent(),
    Value<int?> toAccountId = const Value.absent(),
    Value<String?> counterpartyName = const Value.absent(),
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> lendStartDate = const Value.absent(),
    Value<DateTime?> lendEndDate = const Value.absent(),
    Value<int?> originalTransactionId = const Value.absent(),
    Value<String?> refundNote = const Value.absent(),
    bool? excludeFromIncomeExpense,
    bool? excludeFromBudget,
  }) => TransactionEntry(
    id: id ?? this.id,
    amountCents: amountCents ?? this.amountCents,
    type: type ?? this.type,
    categoryId: categoryId ?? this.categoryId,
    accountId: accountId ?? this.accountId,
    note: note ?? this.note,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    installmentPeriod: installmentPeriod.present
        ? installmentPeriod.value
        : this.installmentPeriod,
    fromAccountId: fromAccountId.present
        ? fromAccountId.value
        : this.fromAccountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    counterpartyName: counterpartyName.present
        ? counterpartyName.value
        : this.counterpartyName,
    startDate: startDate.present ? startDate.value : this.startDate,
    lendStartDate: lendStartDate.present
        ? lendStartDate.value
        : this.lendStartDate,
    lendEndDate: lendEndDate.present ? lendEndDate.value : this.lendEndDate,
    originalTransactionId: originalTransactionId.present
        ? originalTransactionId.value
        : this.originalTransactionId,
    refundNote: refundNote.present ? refundNote.value : this.refundNote,
    excludeFromIncomeExpense:
        excludeFromIncomeExpense ?? this.excludeFromIncomeExpense,
    excludeFromBudget: excludeFromBudget ?? this.excludeFromBudget,
  );
  TransactionEntry copyWithCompanion(TransactionsCompanion data) {
    return TransactionEntry(
      id: data.id.present ? data.id.value : this.id,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      type: data.type.present ? data.type.value : this.type,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      note: data.note.present ? data.note.value : this.note,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      installmentPeriod: data.installmentPeriod.present
          ? data.installmentPeriod.value
          : this.installmentPeriod,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      counterpartyName: data.counterpartyName.present
          ? data.counterpartyName.value
          : this.counterpartyName,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      lendStartDate: data.lendStartDate.present
          ? data.lendStartDate.value
          : this.lendStartDate,
      lendEndDate: data.lendEndDate.present
          ? data.lendEndDate.value
          : this.lendEndDate,
      originalTransactionId: data.originalTransactionId.present
          ? data.originalTransactionId.value
          : this.originalTransactionId,
      refundNote: data.refundNote.present
          ? data.refundNote.value
          : this.refundNote,
      excludeFromIncomeExpense: data.excludeFromIncomeExpense.present
          ? data.excludeFromIncomeExpense.value
          : this.excludeFromIncomeExpense,
      excludeFromBudget: data.excludeFromBudget.present
          ? data.excludeFromBudget.value
          : this.excludeFromBudget,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionEntry(')
          ..write('id: $id, ')
          ..write('amountCents: $amountCents, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('installmentPeriod: $installmentPeriod, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('startDate: $startDate, ')
          ..write('lendStartDate: $lendStartDate, ')
          ..write('lendEndDate: $lendEndDate, ')
          ..write('originalTransactionId: $originalTransactionId, ')
          ..write('refundNote: $refundNote, ')
          ..write('excludeFromIncomeExpense: $excludeFromIncomeExpense, ')
          ..write('excludeFromBudget: $excludeFromBudget')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    amountCents,
    type,
    categoryId,
    accountId,
    note,
    occurredAt,
    createdAt,
    updatedAt,
    installmentPeriod,
    fromAccountId,
    toAccountId,
    counterpartyName,
    startDate,
    lendStartDate,
    lendEndDate,
    originalTransactionId,
    refundNote,
    excludeFromIncomeExpense,
    excludeFromBudget,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionEntry &&
          other.id == this.id &&
          other.amountCents == this.amountCents &&
          other.type == this.type &&
          other.categoryId == this.categoryId &&
          other.accountId == this.accountId &&
          other.note == this.note &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.installmentPeriod == this.installmentPeriod &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.counterpartyName == this.counterpartyName &&
          other.startDate == this.startDate &&
          other.lendStartDate == this.lendStartDate &&
          other.lendEndDate == this.lendEndDate &&
          other.originalTransactionId == this.originalTransactionId &&
          other.refundNote == this.refundNote &&
          other.excludeFromIncomeExpense == this.excludeFromIncomeExpense &&
          other.excludeFromBudget == this.excludeFromBudget);
}

class TransactionsCompanion extends UpdateCompanion<TransactionEntry> {
  final Value<int> id;
  final Value<int> amountCents;
  final Value<TransactionType> type;
  final Value<int> categoryId;
  final Value<int> accountId;
  final Value<String> note;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> installmentPeriod;
  final Value<int?> fromAccountId;
  final Value<int?> toAccountId;
  final Value<String?> counterpartyName;
  final Value<DateTime?> startDate;
  final Value<DateTime?> lendStartDate;
  final Value<DateTime?> lendEndDate;
  final Value<int?> originalTransactionId;
  final Value<String?> refundNote;
  final Value<bool> excludeFromIncomeExpense;
  final Value<bool> excludeFromBudget;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.type = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.note = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.installmentPeriod = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.lendStartDate = const Value.absent(),
    this.lendEndDate = const Value.absent(),
    this.originalTransactionId = const Value.absent(),
    this.refundNote = const Value.absent(),
    this.excludeFromIncomeExpense = const Value.absent(),
    this.excludeFromBudget = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int amountCents,
    required TransactionType type,
    required int categoryId,
    required int accountId,
    this.note = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.installmentPeriod = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.counterpartyName = const Value.absent(),
    this.startDate = const Value.absent(),
    this.lendStartDate = const Value.absent(),
    this.lendEndDate = const Value.absent(),
    this.originalTransactionId = const Value.absent(),
    this.refundNote = const Value.absent(),
    this.excludeFromIncomeExpense = const Value.absent(),
    this.excludeFromBudget = const Value.absent(),
  }) : amountCents = Value(amountCents),
       type = Value(type),
       categoryId = Value(categoryId),
       accountId = Value(accountId);
  static Insertable<TransactionEntry> custom({
    Expression<int>? id,
    Expression<int>? amountCents,
    Expression<String>? type,
    Expression<int>? categoryId,
    Expression<int>? accountId,
    Expression<String>? note,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? installmentPeriod,
    Expression<int>? fromAccountId,
    Expression<int>? toAccountId,
    Expression<String>? counterpartyName,
    Expression<DateTime>? startDate,
    Expression<DateTime>? lendStartDate,
    Expression<DateTime>? lendEndDate,
    Expression<int>? originalTransactionId,
    Expression<String>? refundNote,
    Expression<bool>? excludeFromIncomeExpense,
    Expression<bool>? excludeFromBudget,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountCents != null) 'amount_cents': amountCents,
      if (type != null) 'type': type,
      if (categoryId != null) 'category_id': categoryId,
      if (accountId != null) 'account_id': accountId,
      if (note != null) 'note': note,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (installmentPeriod != null) 'installment_period': installmentPeriod,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (counterpartyName != null) 'counterparty_name': counterpartyName,
      if (startDate != null) 'start_date': startDate,
      if (lendStartDate != null) 'lend_start_date': lendStartDate,
      if (lendEndDate != null) 'lend_end_date': lendEndDate,
      if (originalTransactionId != null)
        'original_transaction_id': originalTransactionId,
      if (refundNote != null) 'refund_note': refundNote,
      if (excludeFromIncomeExpense != null)
        'exclude_from_income_expense': excludeFromIncomeExpense,
      if (excludeFromBudget != null) 'exclude_from_budget': excludeFromBudget,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? amountCents,
    Value<TransactionType>? type,
    Value<int>? categoryId,
    Value<int>? accountId,
    Value<String>? note,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int?>? installmentPeriod,
    Value<int?>? fromAccountId,
    Value<int?>? toAccountId,
    Value<String?>? counterpartyName,
    Value<DateTime?>? startDate,
    Value<DateTime?>? lendStartDate,
    Value<DateTime?>? lendEndDate,
    Value<int?>? originalTransactionId,
    Value<String?>? refundNote,
    Value<bool>? excludeFromIncomeExpense,
    Value<bool>? excludeFromBudget,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      installmentPeriod: installmentPeriod ?? this.installmentPeriod,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      counterpartyName: counterpartyName ?? this.counterpartyName,
      startDate: startDate ?? this.startDate,
      lendStartDate: lendStartDate ?? this.lendStartDate,
      lendEndDate: lendEndDate ?? this.lendEndDate,
      originalTransactionId:
          originalTransactionId ?? this.originalTransactionId,
      refundNote: refundNote ?? this.refundNote,
      excludeFromIncomeExpense:
          excludeFromIncomeExpense ?? this.excludeFromIncomeExpense,
      excludeFromBudget: excludeFromBudget ?? this.excludeFromBudget,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $TransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (installmentPeriod.present) {
      map['installment_period'] = Variable<int>(installmentPeriod.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<int>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (counterpartyName.present) {
      map['counterparty_name'] = Variable<String>(counterpartyName.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (lendStartDate.present) {
      map['lend_start_date'] = Variable<DateTime>(lendStartDate.value);
    }
    if (lendEndDate.present) {
      map['lend_end_date'] = Variable<DateTime>(lendEndDate.value);
    }
    if (originalTransactionId.present) {
      map['original_transaction_id'] = Variable<int>(
        originalTransactionId.value,
      );
    }
    if (refundNote.present) {
      map['refund_note'] = Variable<String>(refundNote.value);
    }
    if (excludeFromIncomeExpense.present) {
      map['exclude_from_income_expense'] = Variable<bool>(
        excludeFromIncomeExpense.value,
      );
    }
    if (excludeFromBudget.present) {
      map['exclude_from_budget'] = Variable<bool>(excludeFromBudget.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amountCents: $amountCents, ')
          ..write('type: $type, ')
          ..write('categoryId: $categoryId, ')
          ..write('accountId: $accountId, ')
          ..write('note: $note, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('installmentPeriod: $installmentPeriod, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('counterpartyName: $counterpartyName, ')
          ..write('startDate: $startDate, ')
          ..write('lendStartDate: $lendStartDate, ')
          ..write('lendEndDate: $lendEndDate, ')
          ..write('originalTransactionId: $originalTransactionId, ')
          ..write('refundNote: $refundNote, ')
          ..write('excludeFromIncomeExpense: $excludeFromIncomeExpense, ')
          ..write('excludeFromBudget: $excludeFromBudget')
          ..write(')'))
        .toString();
  }
}

class $CategoryTemplatesTable extends CategoryTemplates
    with TableInfo<$CategoryTemplatesTable, CategoryTemplateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 32,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 20,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    name,
    description,
    emoji,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryTemplateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    } else if (isInserting) {
      context.missing(_emojiMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryTemplateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryTemplateEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoryTemplatesTable createAlias(String alias) {
    return $CategoryTemplatesTable(attachedDatabase, alias);
  }
}

class CategoryTemplateEntry extends DataClass
    implements Insertable<CategoryTemplateEntry> {
  final int id;

  /// 模板代号,稳定不变(英文 snake_case,如 'office_worker' / 'family')。
  ///
  /// WHY: 用作 UI Key + seed 数据 key,稳定后改 description 不影响功能。
  final String code;

  /// 模板显示名(中文,如 "上班族")。
  final String name;

  /// 模板简介(一句话,如 "覆盖上班族日常场景,12 个高频分类")。
  final String description;

  /// 模板 emoji 头像(UI 卡片用,UTF-16 字符串)。
  ///
  /// WHY: 沿用 ADR-0013 emoji 优先,跨平台一致 + 零依赖。
  final String emoji;
  final DateTime createdAt;
  const CategoryTemplateEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.emoji,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['emoji'] = Variable<String>(emoji);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoryTemplatesCompanion toCompanion(bool nullToAbsent) {
    return CategoryTemplatesCompanion(
      id: Value(id),
      code: Value(code),
      name: Value(name),
      description: Value(description),
      emoji: Value(emoji),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryTemplateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryTemplateEntry(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      emoji: serializer.fromJson<String>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'emoji': serializer.toJson<String>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryTemplateEntry copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    String? emoji,
    DateTime? createdAt,
  }) => CategoryTemplateEntry(
    id: id ?? this.id,
    code: code ?? this.code,
    name: name ?? this.name,
    description: description ?? this.description,
    emoji: emoji ?? this.emoji,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryTemplateEntry copyWithCompanion(CategoryTemplatesCompanion data) {
    return CategoryTemplateEntry(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryTemplateEntry(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, code, name, description, emoji, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryTemplateEntry &&
          other.id == this.id &&
          other.code == this.code &&
          other.name == this.name &&
          other.description == this.description &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt);
}

class CategoryTemplatesCompanion
    extends UpdateCompanion<CategoryTemplateEntry> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> name;
  final Value<String> description;
  final Value<String> emoji;
  final Value<DateTime> createdAt;
  const CategoryTemplatesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoryTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String name,
    required String description,
    required String emoji,
    this.createdAt = const Value.absent(),
  }) : code = Value(code),
       name = Value(name),
       description = Value(description),
       emoji = Value(emoji);
  static Insertable<CategoryTemplateEntry> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoryTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? name,
    Value<String>? description,
    Value<String>? emoji,
    Value<DateTime>? createdAt,
  }) {
    return CategoryTemplatesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $CategoryTemplatesTable categoryTemplates =
      $CategoryTemplatesTable(this);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final TransactionDao transactionDao = TransactionDao(
    this as AppDatabase,
  );
  late final CategoryTemplateDao categoryTemplateDao = CategoryTemplateDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    accounts,
    transactions,
    categoryTemplates,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required String name,
      required String iconName,
      required int colorValue,
      required TransactionType type,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> iconName,
      Value<int> colorValue,
      Value<TransactionType> type,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, CategoryEntry> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionEntry>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'categories__id__transactions__category_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryEntry,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryEntry, $$CategoriesTableReferences),
          CategoryEntry,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                iconName: iconName,
                colorValue: colorValue,
                type: type,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String iconName,
                required int colorValue,
                required TransactionType type,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                iconName: iconName,
                colorValue: colorValue,
                type: type,
                sortOrder: sortOrder,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      CategoryEntry,
                      $CategoriesTable,
                      TransactionEntry
                    >(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryEntry,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryEntry, $$CategoriesTableReferences),
      CategoryEntry,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      required String name,
      Value<int> balanceCents,
      Value<AccountType> type,
      Value<AccountSubType?> subType,
      Value<String?> brandName,
      Value<bool> includeInNetWorth,
      Value<bool> isPinned,
      Value<bool> isDefaultIncomeAccount,
      Value<bool> isDefaultExpenseAccount,
      Value<int?> creditLimit,
      Value<int?> initialDebtCents,
      Value<int?> billingDay,
      Value<int?> dueDay,
      Value<DateTime?> startDate,
      Value<DateTime?> dueDate,
      Value<String?> counterpartyName,
      Value<int?> initialLendBalanceCents,
      Value<DateTime?> initialTime,
      Value<String?> lendCounterpartyName,
      Value<DateTime?> lendDueDate,
      Value<DateTime> createdAt,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int> balanceCents,
      Value<AccountType> type,
      Value<AccountSubType?> subType,
      Value<String?> brandName,
      Value<bool> includeInNetWorth,
      Value<bool> isPinned,
      Value<bool> isDefaultIncomeAccount,
      Value<bool> isDefaultExpenseAccount,
      Value<int?> creditLimit,
      Value<int?> initialDebtCents,
      Value<int?> billingDay,
      Value<int?> dueDay,
      Value<DateTime?> startDate,
      Value<DateTime?> dueDate,
      Value<String?> counterpartyName,
      Value<int?> initialLendBalanceCents,
      Value<DateTime?> initialTime,
      Value<String?> lendCounterpartyName,
      Value<DateTime?> lendDueDate,
      Value<DateTime> createdAt,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, AccountEntry> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionEntry>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: 'accounts__id__transactions__account_id',
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceCents => $composableBuilder(
    column: $table.balanceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<AccountSubType?, AccountSubType, String>
  get subType => $composableBuilder(
    column: $table.subType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultIncomeAccount => $composableBuilder(
    column: $table.isDefaultIncomeAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefaultExpenseAccount => $composableBuilder(
    column: $table.isDefaultExpenseAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialDebtCents => $composableBuilder(
    column: $table.initialDebtCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billingDay => $composableBuilder(
    column: $table.billingDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get initialLendBalanceCents => $composableBuilder(
    column: $table.initialLendBalanceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get initialTime => $composableBuilder(
    column: $table.initialTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lendCounterpartyName => $composableBuilder(
    column: $table.lendCounterpartyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lendDueDate => $composableBuilder(
    column: $table.lendDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceCents => $composableBuilder(
    column: $table.balanceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subType => $composableBuilder(
    column: $table.subType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultIncomeAccount => $composableBuilder(
    column: $table.isDefaultIncomeAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefaultExpenseAccount => $composableBuilder(
    column: $table.isDefaultExpenseAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialDebtCents => $composableBuilder(
    column: $table.initialDebtCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billingDay => $composableBuilder(
    column: $table.billingDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get initialLendBalanceCents => $composableBuilder(
    column: $table.initialLendBalanceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get initialTime => $composableBuilder(
    column: $table.initialTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lendCounterpartyName => $composableBuilder(
    column: $table.lendCounterpartyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lendDueDate => $composableBuilder(
    column: $table.lendDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get balanceCents => $composableBuilder(
    column: $table.balanceCents,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountSubType?, String> get subType =>
      $composableBuilder(column: $table.subType, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<bool> get includeInNetWorth => $composableBuilder(
    column: $table.includeInNetWorth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isDefaultIncomeAccount => $composableBuilder(
    column: $table.isDefaultIncomeAccount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefaultExpenseAccount => $composableBuilder(
    column: $table.isDefaultExpenseAccount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get initialDebtCents => $composableBuilder(
    column: $table.initialDebtCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billingDay => $composableBuilder(
    column: $table.billingDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get initialLendBalanceCents => $composableBuilder(
    column: $table.initialLendBalanceCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get initialTime => $composableBuilder(
    column: $table.initialTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lendCounterpartyName => $composableBuilder(
    column: $table.lendCounterpartyName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lendDueDate => $composableBuilder(
    column: $table.lendDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          AccountEntry,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (AccountEntry, $$AccountsTableReferences),
          AccountEntry,
          PrefetchHooks Function({bool transactionsRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> balanceCents = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<AccountSubType?> subType = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<bool> includeInNetWorth = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isDefaultIncomeAccount = const Value.absent(),
                Value<bool> isDefaultExpenseAccount = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<int?> initialDebtCents = const Value.absent(),
                Value<int?> billingDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> counterpartyName = const Value.absent(),
                Value<int?> initialLendBalanceCents = const Value.absent(),
                Value<DateTime?> initialTime = const Value.absent(),
                Value<String?> lendCounterpartyName = const Value.absent(),
                Value<DateTime?> lendDueDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                balanceCents: balanceCents,
                type: type,
                subType: subType,
                brandName: brandName,
                includeInNetWorth: includeInNetWorth,
                isPinned: isPinned,
                isDefaultIncomeAccount: isDefaultIncomeAccount,
                isDefaultExpenseAccount: isDefaultExpenseAccount,
                creditLimit: creditLimit,
                initialDebtCents: initialDebtCents,
                billingDay: billingDay,
                dueDay: dueDay,
                startDate: startDate,
                dueDate: dueDate,
                counterpartyName: counterpartyName,
                initialLendBalanceCents: initialLendBalanceCents,
                initialTime: initialTime,
                lendCounterpartyName: lendCounterpartyName,
                lendDueDate: lendDueDate,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> balanceCents = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<AccountSubType?> subType = const Value.absent(),
                Value<String?> brandName = const Value.absent(),
                Value<bool> includeInNetWorth = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isDefaultIncomeAccount = const Value.absent(),
                Value<bool> isDefaultExpenseAccount = const Value.absent(),
                Value<int?> creditLimit = const Value.absent(),
                Value<int?> initialDebtCents = const Value.absent(),
                Value<int?> billingDay = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String?> counterpartyName = const Value.absent(),
                Value<int?> initialLendBalanceCents = const Value.absent(),
                Value<DateTime?> initialTime = const Value.absent(),
                Value<String?> lendCounterpartyName = const Value.absent(),
                Value<DateTime?> lendDueDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                balanceCents: balanceCents,
                type: type,
                subType: subType,
                brandName: brandName,
                includeInNetWorth: includeInNetWorth,
                isPinned: isPinned,
                isDefaultIncomeAccount: isDefaultIncomeAccount,
                isDefaultExpenseAccount: isDefaultExpenseAccount,
                creditLimit: creditLimit,
                initialDebtCents: initialDebtCents,
                billingDay: billingDay,
                dueDay: dueDay,
                startDate: startDate,
                dueDate: dueDate,
                counterpartyName: counterpartyName,
                initialLendBalanceCents: initialLendBalanceCents,
                initialTime: initialTime,
                lendCounterpartyName: lendCounterpartyName,
                lendDueDate: lendDueDate,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({transactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (transactionsRefs) db.transactions],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<
                      AccountEntry,
                      $AccountsTable,
                      TransactionEntry
                    >(
                      currentTable: table,
                      referencedTable: $$AccountsTableReferences
                          ._transactionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AccountsTableReferences(
                        db,
                        table,
                        p0,
                      ).transactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      AccountEntry,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (AccountEntry, $$AccountsTableReferences),
      AccountEntry,
      PrefetchHooks Function({bool transactionsRefs})
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      required int amountCents,
      required TransactionType type,
      required int categoryId,
      required int accountId,
      Value<String> note,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int?> installmentPeriod,
      Value<int?> fromAccountId,
      Value<int?> toAccountId,
      Value<String?> counterpartyName,
      Value<DateTime?> startDate,
      Value<DateTime?> lendStartDate,
      Value<DateTime?> lendEndDate,
      Value<int?> originalTransactionId,
      Value<String?> refundNote,
      Value<bool> excludeFromIncomeExpense,
      Value<bool> excludeFromBudget,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<int> id,
      Value<int> amountCents,
      Value<TransactionType> type,
      Value<int> categoryId,
      Value<int> accountId,
      Value<String> note,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int?> installmentPeriod,
      Value<int?> fromAccountId,
      Value<int?> toAccountId,
      Value<String?> counterpartyName,
      Value<DateTime?> startDate,
      Value<DateTime?> lendStartDate,
      Value<DateTime?> lendEndDate,
      Value<int?> originalTransactionId,
      Value<String?> refundNote,
      Value<bool> excludeFromIncomeExpense,
      Value<bool> excludeFromBudget,
    });

final class $$TransactionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionEntry> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<int>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, String>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentPeriod => $composableBuilder(
    column: $table.installmentPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lendStartDate => $composableBuilder(
    column: $table.lendStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lendEndDate => $composableBuilder(
    column: $table.lendEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalTransactionId => $composableBuilder(
    column: $table.originalTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refundNote => $composableBuilder(
    column: $table.refundNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromIncomeExpense => $composableBuilder(
    column: $table.excludeFromIncomeExpense,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get excludeFromBudget => $composableBuilder(
    column: $table.excludeFromBudget,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentPeriod => $composableBuilder(
    column: $table.installmentPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lendStartDate => $composableBuilder(
    column: $table.lendStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lendEndDate => $composableBuilder(
    column: $table.lendEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalTransactionId => $composableBuilder(
    column: $table.originalTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refundNote => $composableBuilder(
    column: $table.refundNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromIncomeExpense => $composableBuilder(
    column: $table.excludeFromIncomeExpense,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get excludeFromBudget => $composableBuilder(
    column: $table.excludeFromBudget,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get installmentPeriod => $composableBuilder(
    column: $table.installmentPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fromAccountId => $composableBuilder(
    column: $table.fromAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get counterpartyName => $composableBuilder(
    column: $table.counterpartyName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get lendStartDate => $composableBuilder(
    column: $table.lendStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lendEndDate => $composableBuilder(
    column: $table.lendEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalTransactionId => $composableBuilder(
    column: $table.originalTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refundNote => $composableBuilder(
    column: $table.refundNote,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get excludeFromIncomeExpense => $composableBuilder(
    column: $table.excludeFromIncomeExpense,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get excludeFromBudget => $composableBuilder(
    column: $table.excludeFromBudget,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionEntry,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (TransactionEntry, $$TransactionsTableReferences),
          TransactionEntry,
          PrefetchHooks Function({bool categoryId, bool accountId})
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> accountId = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> installmentPeriod = const Value.absent(),
                Value<int?> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<String?> counterpartyName = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> lendStartDate = const Value.absent(),
                Value<DateTime?> lendEndDate = const Value.absent(),
                Value<int?> originalTransactionId = const Value.absent(),
                Value<String?> refundNote = const Value.absent(),
                Value<bool> excludeFromIncomeExpense = const Value.absent(),
                Value<bool> excludeFromBudget = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                amountCents: amountCents,
                type: type,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                installmentPeriod: installmentPeriod,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                counterpartyName: counterpartyName,
                startDate: startDate,
                lendStartDate: lendStartDate,
                lendEndDate: lendEndDate,
                originalTransactionId: originalTransactionId,
                refundNote: refundNote,
                excludeFromIncomeExpense: excludeFromIncomeExpense,
                excludeFromBudget: excludeFromBudget,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountCents,
                required TransactionType type,
                required int categoryId,
                required int accountId,
                Value<String> note = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> installmentPeriod = const Value.absent(),
                Value<int?> fromAccountId = const Value.absent(),
                Value<int?> toAccountId = const Value.absent(),
                Value<String?> counterpartyName = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> lendStartDate = const Value.absent(),
                Value<DateTime?> lendEndDate = const Value.absent(),
                Value<int?> originalTransactionId = const Value.absent(),
                Value<String?> refundNote = const Value.absent(),
                Value<bool> excludeFromIncomeExpense = const Value.absent(),
                Value<bool> excludeFromBudget = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                amountCents: amountCents,
                type: type,
                categoryId: categoryId,
                accountId: accountId,
                note: note,
                occurredAt: occurredAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                installmentPeriod: installmentPeriod,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                counterpartyName: counterpartyName,
                startDate: startDate,
                lendStartDate: lendStartDate,
                lendEndDate: lendEndDate,
                originalTransactionId: originalTransactionId,
                refundNote: refundNote,
                excludeFromIncomeExpense: excludeFromIncomeExpense,
                excludeFromBudget: excludeFromBudget,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$TransactionsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$TransactionsTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$TransactionsTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionEntry,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (TransactionEntry, $$TransactionsTableReferences),
      TransactionEntry,
      PrefetchHooks Function({bool categoryId, bool accountId})
    >;
typedef $$CategoryTemplatesTableCreateCompanionBuilder =
    CategoryTemplatesCompanion Function({
      Value<int> id,
      required String code,
      required String name,
      required String description,
      required String emoji,
      Value<DateTime> createdAt,
    });
typedef $$CategoryTemplatesTableUpdateCompanionBuilder =
    CategoryTemplatesCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> name,
      Value<String> description,
      Value<String> emoji,
      Value<DateTime> createdAt,
    });

class $$CategoryTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryTemplatesTable> {
  $$CategoryTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryTemplatesTable> {
  $$CategoryTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryTemplatesTable> {
  $$CategoryTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoryTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryTemplatesTable,
          CategoryTemplateEntry,
          $$CategoryTemplatesTableFilterComposer,
          $$CategoryTemplatesTableOrderingComposer,
          $$CategoryTemplatesTableAnnotationComposer,
          $$CategoryTemplatesTableCreateCompanionBuilder,
          $$CategoryTemplatesTableUpdateCompanionBuilder,
          (
            CategoryTemplateEntry,
            BaseReferences<
              _$AppDatabase,
              $CategoryTemplatesTable,
              CategoryTemplateEntry
            >,
          ),
          CategoryTemplateEntry,
          PrefetchHooks Function()
        > {
  $$CategoryTemplatesTableTableManager(
    _$AppDatabase db,
    $CategoryTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoryTemplatesCompanion(
                id: id,
                code: code,
                name: name,
                description: description,
                emoji: emoji,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String name,
                required String description,
                required String emoji,
                Value<DateTime> createdAt = const Value.absent(),
              }) => CategoryTemplatesCompanion.insert(
                id: id,
                code: code,
                name: name,
                description: description,
                emoji: emoji,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryTemplatesTable,
      CategoryTemplateEntry,
      $$CategoryTemplatesTableFilterComposer,
      $$CategoryTemplatesTableOrderingComposer,
      $$CategoryTemplatesTableAnnotationComposer,
      $$CategoryTemplatesTableCreateCompanionBuilder,
      $$CategoryTemplatesTableUpdateCompanionBuilder,
      (
        CategoryTemplateEntry,
        BaseReferences<
          _$AppDatabase,
          $CategoryTemplatesTable,
          CategoryTemplateEntry
        >,
      ),
      CategoryTemplateEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$CategoryTemplatesTableTableManager get categoryTemplates =>
      $$CategoryTemplatesTableTableManager(_db, _db.categoryTemplates);
}
