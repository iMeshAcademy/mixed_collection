import 'package:mixed_collection/mixed_collection.dart';

class StringCollectionEntry extends CollectionEntry<String> {
  StringCollectionEntry(String value) : super(value);
  @override
  dynamic getValue(String key) {
    return item;
  }

  @override
  String toString() {
    return item;
  }
}
