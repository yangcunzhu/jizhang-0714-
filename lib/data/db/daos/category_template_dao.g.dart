// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_template_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryTemplateDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoryTemplatesTable get categoryTemplates =>
      attachedDatabase.categoryTemplates;
  $CategoriesTable get categories => attachedDatabase.categories;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  CategoryTemplateDaoManager get managers => CategoryTemplateDaoManager(this);
}

class CategoryTemplateDaoManager {
  final _$CategoryTemplateDaoMixin _db;
  CategoryTemplateDaoManager(this._db);
  $$CategoryTemplatesTableTableManager get categoryTemplates =>
      $$CategoryTemplatesTableTableManager(
        _db.attachedDatabase,
        _db.categoryTemplates,
      );
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
}
