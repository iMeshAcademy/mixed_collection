part of mixed_collection;

typedef int SortComparerCallback<T extends CollectionEntry>(
    T record1, T record2);

/// Mixin, which provide sorting functionality.
mixin Sortable<S, T extends CollectionEntry<S>> {
  List<dynamic> _sorters = List<dynamic>();
  bool _sortSuspended = false;

  List<dynamic> get sorters => this._sorters;

  set sorters(List<dynamic> value) => this._sorters = value;

  bool get hasSorters {
    return this._sorters.isNotEmpty;
  }

  void onSorted();

  /// Sort failed.
  void onSortFailed();

  void supendSort() {
    this._sortSuspended = true;
  }

  void resumeSort() {
    this._sortSuspended = false;
  }

  bool _isSorterEnabled(dynamic value) {
    if (value is Function) {
      return true;
    } else if (value is Map<String, dynamic>) {
      return value.containsKey("enabled") ? value["enabled"] as bool : false;
    } else if (value is String) {
      Map<String, dynamic> sorter =
          this._sorters.firstWhere((it) => it["name"] == value);
      if (null != sorter) {
        return sorter.containsKey("enabled")
            ? sorter["enabled"] as bool
            : false;
      }
    }

    return false;
  }

  void removeSorter(dynamic sorter) {
    if (sorter == null) {
      return;
    }
    if (sorter is Function && this.sorters.contains(sorter)) {
      this.sorters.remove(sorter);
    } else if (sorter is Map<String, dynamic>) {
      if (this.sorters.contains(sorter)) {
        this.sorters.remove(sorter);
      } else if (sorter.containsKey("name")) {
        this.removeSorterByName(sorter["name"]);
      }
    }
  }

  void removeSorterByName(String name) {
    if (this.sorters != null) {
      this.sorters.removeWhere((s) => s["name"] == name);
    }
  }

  void clearSorters() {
    this._sorters.clear();
  }

  void enableSorter(dynamic value) {
    this._toggleSorterState(value, true);
  }

  void _toggleSorterState(dynamic value, bool state) {
    if (value is Function) {
      if (this.sorters.contains(value) == false) {
        this.sorters.add(value);
      }
    } else if (value is Map<String, dynamic>) {
      if (this.sorters.contains(value)) {
        value["enabled"] = state;
      }
    } else if (value is String) {
      Map<String, dynamic> sorter =
          this.sorters.singleWhere((it) => it["name"] == value);
      if (null != sorter) {
        sorter["enabled"] = state;
      }
    }
  }

  void disableAllSorters() {
    for (int i = 0; i < this._sorters.length; i++) {
      this.disableSorter(this._sorters[i]);
    }
  }

  void enableAllSorters() {
    for (int i = 0; i < this._sorters.length; i++) {
      this.enableSorter(this._sorters[i]);
    }
  }

  void disableSorter(dynamic value) {
    this._toggleSorterState(value, false);
  }

  ///
  ///   Sort list routine. This helper perform basic sorting operation based on the sort logic.
  ///
  ///   {
  ///     property : fieldName,
  ///     direction : asc|desc
  ///     caseSensitive: true|false
  ///   }
  ///
  @protected
  void sortCollection(List<T> recs, CollectionOperationCallback callback) {
    // Sorting is suspended, return.
    if (this._sortSuspended ||
        this.hasSorters == false ||
        null == recs ||
        recs.isEmpty) {
      if (null != callback) callback(null, "Sort Failed");
      return;
    }

    for (var i = 0; i < this.sorters.length; i++) {}

    List<Function> fns = List<Function>();

    this.sorters.forEach((sorter) {
      if (this._isSorterEnabled(sorter)) {
        print("Sorter is enabled - $sorter");
        Function sort;
        bool caseSensitive = false;
        String direction = "";
        Function comparer;
        if (sorter is SortComparerCallback) {
          sort = sorter;
        } else if (sorter is Map<String, dynamic>) {
          caseSensitive = sorter['caseSensitive'] ?? false;
          direction = sorter["direction"] ?? "asc";

          comparer = sorter["comparer"];

          sort = (T a, T b) {
            dynamic val1 = a.getValue(sorter["property"]);
            dynamic val2 = b.getValue(sorter["property"]);

            if (caseSensitive && val1 is String) {
              val1 = (val1 as String).toLowerCase();
              val2 = (val2 as String).toLowerCase();
            }

            var sortValue =
                comparer != null ? comparer(val1, val2) : val1.compareTo(val2);

            if (direction != "asc") {
              sortValue *= -1;
            }

            return sortValue;
          };
        }
        fns.add(sort);
      }
    });

    recs.sort((a, b) {
      int sort = 0;

      for (var i = 0; i < fns.length; i++) {
        sort = fns[i](a, b);
        if (sort != 0) {
          break;
        }
      }

      return sort;
    });

    if (null != callback) {
      callback(recs, null);
    }
  }

  /// This function provide sorting support to the store.
  /// Sorter can be a sort configuration, understood by the implementation or a callback function.
  /// If callback function is specified, that function shall be used as a comparer by the implementer.
  @protected
  void applySorter(List<T> records, dynamic sorter,
      [bool fireEvent = true, bool force = false]) {
    if (null == records || records.isEmpty) {
      this.onSortFailed();
      return; // Either already sorted, or no need to sort the list.
    }

    if (null != sorter && false == this._sorters.contains(sorter)) {
      // Add  new sorter to the list.
      this._sorters.add(sorter);
    }

    // Perform sort operation.
    sortCollection(records, (data, error) {
      if (error != null) {
        onSortFailed();
      } else {
        // Flag sorted to true.
        if (fireEvent) onSorted(); // Fire sort event.
      }
    });
  }
}
