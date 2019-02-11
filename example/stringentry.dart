import 'package:mixed_collection/mixed_collection.dart';

// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

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
