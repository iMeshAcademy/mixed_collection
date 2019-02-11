part of mixed_collection;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// Callback function to perform filter operation.
/// If the return value is [true] then that record will be included in the filtered result.
/// This function accepts [Model] as input parameter.
typedef bool FilterCallback<T>(T record, dynamic data);

/// Result of a database operation with the [Store] or [Storage]
/// Check  [result] or [error] in order to understand status of the operation.
typedef void CollectionOperationCallback<T>(dynamic result, dynamic error);

///
/// Mixin, which provide filterable support for the store.
/// Store, by default won't support this mixin.
mixin Filterable<S, T extends CollectionEntry<S>> {
  bool _suspendFilters = false;

  bool get filtersSuspended => this._suspendFilters;

  List<dynamic> _filters = List<dynamic>();

  /// List of filters in the filterable collection.
  List<dynamic> get filters => this._filters;

  /// Update list of filters with the collection.
  set filters(List<dynamic> value) => this._filters = value;

  ///
  /// Filter API.
  ///  Use this API to perform filter operation.
  /// [configOrCallback] - a filter configuration or filterCallbackFuntion.
  /// [notify] - Default to true. Supply false if no events need to be fired.
  /// [force] - This parameter is used to perform force filtering. If supplied -
  /// filter operation will be performed without checking internal state.
  ///
  filterBy([dynamic configOrCallback, bool notify, bool force, dynamic data]) {
    applyFilter(configOrCallback, notify ?? true, force ?? false, data);
  }

  /// This function provide mechanism to filter store entries.
  /// Filters can be based on filter configurations or based on filter callback function.
  /// Refer [filterBy] to check valid configurations.
  @protected
  void applyFilter(dynamic filter,
      [bool notify = true, bool bForce = false, dynamic data]) {
    // Perform sanity of input fields.
    if (null != filter && this._filters.contains(filter) == false) {
      this._filters.add(filter);
    }

    if (false == bForce && false == hasFilters) {
      if (notify) onFilterFailed();
      return;
    }

    this.performFilter(this.getAllRecords(), data, (result, error) {
      // Emit filter event if it is required in the current operation context.
      if (false == this.filtersSuspended) {
        if (result != null) {
          onFiltered(result, notify ?? true);
        } else {
          this.onFilterFailed();
        }
      }
    });
  }

  @protected
  List<T> getAllRecords();

  @protected
  List<T> getFilteredRecords();

  ///
  /// Routine which perform filter operation on the collection.
  /// [records] - List of records which needs to be filtered.
  /// [callback] - A callback, which emits success or failure with results.
  ///
  @protected
  void performFilter(
      List<T> records, dynamic data, CollectionOperationCallback callback) {
    if (this._suspendFilters) {
      callback(null, "Filter is suspended");
      return;
    }
    List<T> filtered = List<T>();
    records.forEach((rec) {
      bool bFiltered = true;
      this.filters.forEach((filter) {
        if (null != filter) {
          if (filter is FilterCallback) {
            bFiltered &= filter(rec, data);
          } else {
            if (filter is Map<String, dynamic>) {
              dynamic val = rec.getValue(filter["property"]);
              dynamic filterValue = filter["value"];
              filterValue = filterValue ?? data;
              bool exactMatch = filter["exactMatch"] ?? true;
              String rule = filter["rule"] ?? "";
              bool caseSensitive = filter["caseSensitive"] ?? false;
              FilterCallback cb = filter["callback"] ?? null;
              if (cb != null) {
                bFiltered &= cb(rec, filterValue);
              } else {
                if (false == caseSensitive && (val is String)) {
                  val = (val as String).toLowerCase();
                  filterValue = (filterValue as String).toLowerCase();
                }

                if (exactMatch) {
                  bFiltered &= val == filterValue;
                } else {
                  if (rule.isNotEmpty) {
                    // Assuming this is a string comparison.
                    switch (rule) {
                      case "beginsWith":
                        bFiltered &= (val as String).startsWith(filterValue);
                        break;
                      case "endswith":
                        bFiltered &= (val as String).endsWith(filterValue);
                        break;
                      case "contains":
                        bFiltered &= (val as String).contains(filterValue);
                        break;
                    } // Switch
                  } // Rule empty.
                } // Not exact match
              }
            } // filter typecast
          } // else config.
        } // Loop for filter map.
      });

      if (bFiltered) {
        filtered.add(rec);
      }
    });

    if (null != callback) {
      callback(filtered, null);
    }
  }

  /// Remove a particular filter by [name] or by [item].
  void removeFilter(String name, dynamic item) {
    if ((null == name || name.isEmpty) || null == item) {
      return;
    }

    int filterLen = this._filters.length;

    this._filters.removeWhere((it) {
      if (item != null) {
        return it == item;
      } else {
        if (it is Map<String, dynamic>) {
          if (it["name"] == name) {
            return true;
          }
        }
      }
      return false;
    });

    if (this._filters.length != filterLen) {
      this.filterBy(null, true, true);
    }
  }

  /// Remove all cached filters.
  /// Use this API to cleanup your unwanted filters,like search or other filters.
  /// This will not remove any cached filters in the collection.
  void clearTemporaryFilters() {
    int filterLen = this._filters.length;
    this._filters.removeWhere((it) {
      if (it is Map<String, dynamic>) {
        if (it["cached"] == false) {
          return true;
        }
      }
    });
    if (this._filters.length != filterLen) {
      this.filterBy(null, true, true);
    }
  }

  /// Empty filters. This shall clear all filters.
  void clearFilters() {
    this._filters.clear();
    this.onFiltersCleared();
  }

  /// Fire filtered. Implementer of this function can provide appropriate implementation.
  void onFiltered(List<T> data, [bool emit = false]);

  /// Just to notify that filter operation has failed.
  void onFilterFailed();

  void onFiltersCleared();

  /// Suspend filter operation.
  void suspendFilter() {
    this._suspendFilters = true;
  }

  /// Resume filter operation.
  void resumeFilters() {
    this._suspendFilters = false;
  }

  /// Check if any valid filters are there in cache.
  bool get hasFilters => this._filters.isNotEmpty;
}
