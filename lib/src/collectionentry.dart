part of mixed_collection;

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
