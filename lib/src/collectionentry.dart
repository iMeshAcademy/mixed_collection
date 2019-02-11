part of mixed_collection;

// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// An abstraction for collection entry.
class CollectionEntry<T extends dynamic> {
  final T item;
  CollectionEntry(this.item);

  /// Get the value associated with the collection entry.
  /// Usually the entry would have a Map<String,dynamic> configuration.
  /// Using the key to retrieve the value from the map.
  ///
  /// For simple collection entry like [StringCollectionEntry], the 'key' could be empty.
  ///
  dynamic getValue(String key) {
    if (key == null || key.isEmpty) {
      return item;
    }
    return item is Map<String, dynamic> ? item[key] ?? item : item;
  }
}
