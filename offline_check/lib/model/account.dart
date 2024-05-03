import 'package:realm/realm.dart';
part 'account.realm.dart';

@RealmModel()
class _Account {
  @PrimaryKey()
  @MapTo('_id')
  late String id;
  @MapTo('name')
  late String name;
  @MapTo('phone')
  late String phone;
}