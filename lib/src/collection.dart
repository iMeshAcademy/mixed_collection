part of mixed_collection;

/// A mixed collection class, which performs automatic sorting, filtering and
/// emits events once the operations are performed. This collection can be used
/// for classes which extends from [CollectionEntry].
///
class Collection<S, T extends CollectionEntry<S>>
    with Filterable<S, T>, Sortable<S, T>, EventEmitter {
  List<T> _allRecords = List<T>();
  List<T> _filteredRecords = List<T>();

  List<T> _cachedRecords;

  bool _filtered = false;
  bool get filtered => this._filtered;

  bool _suspendFilters = false;

  bool _sorted = false;
  bool get sorted => _sorted;

  /// Called from filterable to notify failed filter operation.
  /// This will emit a collection error.
  @override
  @protected
  void onFilterFailed() {
    // Check the reason why filter is failed.
    // Filter might have failed because the list is empty or no filters.
    // Update fields accordingly.

    if (this.getAllRecords().isEmpty || false == hasFilters) {
      this._filteredRecords = List<T>();
      this._filtered = false;
      this._cachedRecords = null;
    }

    emit("error", this,
        new CollectionError("filter", "Filter operation failed", null));
  }

  /// Notification from filterable to inform success filtering operation.
  @override
  @protected
  void onFiltered(List<T> data, [bool notify = false]) {
    this._filtered = this._allRecords.isNotEmpty && this.hasFilters;
    this._filteredRecords = data;
    this._cachedRecords = null;

    if (notify) emit("filter", this, this.records);
  }

  /// Sort operation failed. Notification from sortable.
  @override
  @protected
  void onSortFailed() {
    this._sorted = false;
    this._cachedRecords = null;
    emit("error", this,
        new CollectionError("sort", "Sort operation failed", null));
  }

  /// Sort operation succeeded, notification from sortable.
  @override
  @protected
  void onSorted() {
    this._sorted = true;
    this._cachedRecords = null;
    emit("sort", this);
  }

  /// Get all records, unfiltered, from the collection.
  /// This is reference to the actual collection, so modifying this would modify the collection itself.
  /// DO NOT modify the collection directly. Use other collection APIs instead.
  @override
  List<T> getAllRecords() {
    return this._allRecords;
  }

  /// Get only the filtered collection.
  /// Modifying this from outside collection class is not permanent.
  /// Any modification made to this will be lost once a next filter operation is performed.
  ///
  /// DO NOT modify the collection directly. Use other collection APIs instead.
  @override
  List<T> getFilteredRecords() {
    return this._filteredRecords;
  }

  /// A notification from [Filterable] to indicate once filters are cleared.
  @override
  void onFiltersCleared() {
    this._filteredRecords.clear();
    this._filtered = false;
    this._cachedRecords = null;

    emit("filter", this, records);
  }

  ///
  /// Getter to retrieve collection records.
  /// This does provide a shallow copy.
  /// For performance consideration, a shallow copy is created and sent back.
  ///
  /// Doesn't guarantee thread safety.
  ///
  ///
  List<T> get records {
    if (null != this._cachedRecords) return _cachedRecords;

    /// Never return null list. Make sure alway the list will be valid, atleast an empty list will do.
    this._cachedRecords = this._filtered
        ? getFilteredRecords().sublist(0)
        : getAllRecords().sublist(0);

    return _cachedRecords;
  }

  /// Load records to collection.
  /// [records] - A list of records to be loaded into the collection.
  /// [callback] - A [CollectionOperationCallback] used to indicate collection operation status
  ///
  void load(List<T> records, CollectionOperationCallback callback) {
    if (null != records) {
      this._allRecords = records;
      applySorter(this._allRecords, null, false);
      applyFilter(null, false);
      if (null != callback) {
        callback(this.records, null);
      }
      emit("load", this, this.records);
    } else {
      if (null != callback) {
        callback(this.records,
            new CollectionError("load", "Collection can't be null", null));
      }
      emit("error", this,
          new CollectionError("load", "Collection can't be null", null));
    }
  }

  /// Add a particular entry to collection.
  /// [rec] - A [CollectionEntry] instance.
  /// [callback] - A [CollectionOperationCallback] callback.
  void add(T rec, CollectionOperationCallback callback) {
    this._allRecords.add(rec);
    this._cachedRecords = null;
    applySorter(this._allRecords, null, false, true);
    if (this.filtered || hasFilters) {
      applyFilter(null, false, true);
    }
    if (null != callback) {
      callback(1, null);
    }
    emit("add", this, rec);
  }

  /// Remove records from collection.
  /// [model] - A [CollectionEntry] instance.
  /// [callback] - A [CollectionOperationCallback] callback.
  ///
  /// This does perform filter if the collection was filtered already.
  ///
  void remove(T model, CollectionOperationCallback callback) {
    if (null != model && this._allRecords.contains(model)) {
      this._allRecords.remove(model);
      this._cachedRecords = null;
      if (this.filtered) {
        applyFilter(null, false, true);
      }
      if (null != callback) {
        callback(1, null);
      }
      emit("remove", this, model);
    } else {
      if (null != callback) {
        callback(
            0,
            new CollectionError(
                "remove", "Record - $model doesn't exist in database.", model));
      }
      emit(
          "error",
          this,
          new CollectionError(
              "remove", "Record - $model doesn't exist in database.", model));
    }
  }

  /// Update a record in the collection.
  /// [model] - A [CollectionEntry] instance.
  /// [callback] - A [CollectionOperationCallback] callback.
  /// The update results in a filter and sort if it is enabled.
  void update(T model, CollectionOperationCallback callback) {
    int index = this._allRecords.indexOf(model);

    if (index >= 0) {
      this._allRecords.replaceRange(index, index + 1, [model]);
      this._cachedRecords = null;
      applySorter(this._allRecords, null, false, true);
      applyFilter(null, false, true);
      if (null != callback) {
        callback(1, null);
      }

      emit("update", this, model);
    } else {
      if (null != callback) {
        callback(
            0,
            new CollectionError(
                "update", "The record $model doesn't exist", model));
      }
      emit(
          "error",
          this,
          new CollectionError(
              "update", "The record $model doesn't exist", model));
    }
  }

  ///
  /// An API to clear all records. This is not reversable.
  ///
  void clearRecords(CollectionOperationCallback callback) {
    this._allRecords.clear();
    this._cachedRecords = null;
    applySorter(this._allRecords, null, false, true);
    applyFilter(null, false, true);
    if (null != callback) {
      callback(1, null);
    }
    emit("clear", this, this._allRecords);
  }

  /// Sort the collection.
  /// [config] - A sort configuration or a comparer. Null - If sorting needed to be performed with existing sorters.
  /// [fireEvent] - [true] - Collection emit sort events. [false] - otherwise.
  /// [force] - [true] - forceful sorting. This will perform sort irrespective of state. [false] - state is verified before sorting.
  void sort([dynamic config, bool fireEvent = true, bool force = false]) {
    applySorter(this._allRecords, config, fireEvent, force);
  }

  /// Perform filter operation on collection.
  /// [configOrCallback] - A filter config or [FilterCallback]
  /// [notify] - [true] - collection will emit "filter" events. [false] - collection will not emit events.
  /// [data] - Additional data to be passed to the filter API.
  /// Very useful, if [FilterCallback] is defined elsewhere and don't have access to the "query or data".
  ///
  void filter(
      [dynamic configOrCallback, bool notify, bool force, dynamic data]) {
    filterBy(configOrCallback, notify, force, data);
  }

  /// Get the index of the record in the collection.
  /// Returns index from filtered collection, if it is filtered, otherwise return index in the actual collection.
  int indexOf(T rec, [bool ignoreFilter = false]) =>
      ignoreFilter || false == this._filtered
          ? this.getAllRecords().indexOf(rec)
          : this.getFilteredRecords().indexOf(rec);

  int firstIndexWhere(bool test(T element),
      [int start = 0, bool ignoreFilter = false]) {
    int i = start >= 0 && start < this.length ? start : 0;
    List<T> recs = ignoreFilter || false == this._filtered
        ? this.getAllRecords()
        : this.getFilteredRecords();
    for (; i < recs.length; i++) {
      var rec = recs[i];
      if (test(rec)) {
        return i;
      }
    }

    return -1;
  }

  int lastIndexWhere(bool test(T element),
      [int start = 0, bool ignoreFilter = false]) {
    List<T> recs = ignoreFilter || false == this._filtered
        ? this.getAllRecords()
        : this.getFilteredRecords();

    int i = start >= 0 && start < recs.length ? start : recs.length - 1;

    for (; i >= 0; i--) {
      var rec = recs[i];
      if (test(rec)) {
        return i;
      }
    }

    return -1;
  }

  T firstWhere(bool test(T element), [bool ignoreFilter = false]) {
    List<T> recs = ignoreFilter || false == this._filtered
        ? this.getAllRecords()
        : this.getFilteredRecords();
    for (var i = 0; i < recs.length; i++) {
      var rec = recs[i];
      if (test(rec)) {
        return rec;
      }
    }

    return null;
  }

  List<T> take(bool where(T element), [bool ignoreFilter = false]) {
    List<T> items = List<T>();
    List<T> recs = ignoreFilter || false == this._filtered
        ? this.getAllRecords()
        : this.getFilteredRecords();
    for (var i = 0; i < recs.length; i++) {
      var rec = recs[i];
      if (where(rec)) {
        items.add(rec);
      }
    }

    return items;
  }

  operator [](int index) {
    if (index < this.length && index >= 0) {
      return this.records[index];
    }

    return null;
  }

  int get length => this.records.length;
}
