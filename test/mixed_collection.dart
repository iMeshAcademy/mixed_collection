// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

import 'package:mixed_collection/mixed_collection.dart';
import 'package:test/test.dart';

import '../example/stringentry.dart';

Collection collection;
void main() {
  setUp(() {
    collection = new Collection();
  });

  testLoad();
  testAdd();
  testRemove();
  testUpdate();
  testSort();
  testFilter();
}

void testLoad() {
  group("load", () {
    test("Load items to store", () {
      var items = ["John", "Harry", "Albert", "Paul", "Emilie", "Frank"];

      Collection collection = new Collection();
      expect(collection.length, 0);
      var entries =
          items.map((item) => new StringCollectionEntry(item)).toList();
      collection.load(entries, (res, err) {
        expect(collection.length, 6);
      });
    });
  });
}

void testAdd() {
  group("add", () {
    test("add one item", () {
      int count = collection.length;
      CollectionEntry entry = new StringCollectionEntry("item1");
      collection.add(entry, (res, err) {
        expect(collection.length, count + 1);
      });
    });
  });
}

void testRemove() {
  group("remove", () {
    test("Test remove single", () {
      var items = ["John", "Harry", "Albert", "Paul", "Emilie", "Frank"];

      Collection collection = new Collection();
      expect(collection.length, 0);
      var entries =
          items.map((item) => new StringCollectionEntry(item)).toList();
      collection.load(entries, (res, err) {
        expect(collection.length, 6);
      });

      var item = collection.firstWhere((element) => element.item == "Albert");
      if (item != null) {
        int currentLength = collection.length;
        collection.remove(item, (res, err) {
          expect(collection.length, currentLength - 1);
        });
      }
    });
  });
}

void testUpdate() {
  group("update", () {
    test("Update single", () {
      var items = ["John", "Harry", "Albert", "Paul", "Emilie", "Frank"];

      Collection<String, TestStringEntry> collection =
          new Collection<String, TestStringEntry>();
      expect(collection.length, 0);
      var entries = items.map((item) => new TestStringEntry(item)).toList();
      collection.load(entries, (res, err) {
        expect(collection.length, 6);
      });

      TestStringEntry item =
          collection.firstWhere((element) => element.getValue('') == "Albert");
      if (item != null) {
        item.item = "Ramesh";
        collection.update(item, (res, err) {
          item = collection.firstWhere((element) => element.item == "Ramesh");
          expect(item != null, true);
        });
      }
    });
  });
}

void testSort() {
  group("sort", () {
    test("Sort collection", () {
      var items = ["John", "Harry", "Albert", "Paul", "Emilie", "Frank"];

      Collection<String, TestStringEntry> collection =
          new Collection<String, TestStringEntry>();
      expect(collection.length, 0);
      var entries = items.map((item) => new TestStringEntry(item)).toList();
      collection.load(entries, (res, err) {
        expect(collection.length, 6);
      });

      TestStringEntry item = collection[0];
      collection.sort(sortByStringAsc);
      expect(item != collection[0], true);
    });
  });
}

void testFilter() {
  group("filter", () {
    test("Filter collection", () {
      var items = ["John", "Harry", "Albert", "Paul", "Emilie", "Frank"];

      Collection<String, TestStringEntry> collection =
          new Collection<String, TestStringEntry>();
      expect(collection.length, 0);
      var entries = items.map((item) => new TestStringEntry(item)).toList();
      collection.load(entries, (res, err) {
        expect(collection.length, 6);
      });

      expect(collection.length, 6);

      collection.filter(filterByNameStartsWith, true, true, "A");
      expect(collection.records.length, 1);
    });
  });
}

class TestStringEntry extends StringCollectionEntry {
  String item = '';
  TestStringEntry(String value) : super(value) {
    this.item = value;
  }

  @override
  dynamic getValue(String name) {
    return item;
  }

  void setValue(String value) {
    this.item = value;
  }
}

int sortByStringAsc(dynamic a, dynamic b) {
  if (a == null) return -1;
  if (b == null) return 0;
  return a.toString().compareTo(b.toString());
}

bool filterByNameStartsWith(dynamic entry, dynamic data) {
  if (null != entry && null != data) {
    return (entry.getValue('') as String).startsWith(data);
  }

  return false;
}
