# mixed_collection

A sortable, filterable collection, which can be clubbed with configurable filter and/or sorters to enable sorting or filtering support.

The main features of this custom data structure is listed below.
* Support multiple filters.
* Filters can be added on the fly. 
* Filters can be filter callbacks or configurations.
* Filters can be cached.
* Supports multiple sorters.
* Sorters can be activated/deactivated by name/callback.
* Sorters can be comparators or configurations.
* APIs to manipulate sort and filter logic.
* Iterators and multiple helper functions.
* Simple interface for the data model for the collection.
* Supports multiple mixins, which can be used in third party applications.

Example usage.

```Dart
bool filterByNameStartsWith(dynamic entry, dynamic data) {
  if (null != entry && null != data) {
    return (entry.getValue('') as String).startsWith(data);
  }

  return false;
}

bool containsFilter(dynamic entry, dynamic data) {
  if (null != entry && null != data) {
    return (entry.getValue('') as String).contains(data);
  }

  return false;
}

int sortByStringAsc(dynamic a, dynamic b) {
  if (a == null) return -1;
  if (b == null) return 0;
  return a.toString().compareTo(b.toString());
}

int sortByStringdesc(dynamic a, dynamic b) {
  if (a == null) return -1;
  if (b == 1) return 0;
  return b.toString().compareTo(a.toString());
}

void main() {
  var items = ["John", "Harry", "Albert", "Paul", "Emilie", "Frank"];

  Collection collection = new Collection();
  var entries = items.map((item) => new StringCollectionEntry(item)).toList();
  collection.load(entries, (res, err) {
    print(collection.count);
  });

  collection.filter(filterByNameStartsWith, true, true, "A");
  assert(collection.records.length == 1);

  collection.clearFilters();
  collection.filter(containsFilter, true, true, "rr");
  assert(collection.records.length == 1);
  var filters = [
    {"callback": filterByNameStartsWith, "value": "A"},
    {"callback": containsFilter, "value": "er"}
  ];

  // Perform this operation if you have filtered the collection already.
  collection.suspendFilter();
  collection.clearFilters();

  // Add the new filter to the collection.
  // This is one way you can change filtering at run time.
  collection.filters.addAll(filters);

  // Let collection resume filtering. A next call to filter API will perfrom filtering.
  collection.resumeFilters();
  collection.filter();
  assert(collection.records.length == 1);

// Remove all filters.
  collection.clearFilters();

  print("Actual Collection");
  collection.records.forEach((f) => print(f.item));

  print("Sort By Ascending");
  collection.sort(sortByStringAsc);
  collection.records.forEach((f) => print(f.item));

  collection.clearSorters();
  print("Sort By Descending");

  // Sort by using a custom comparer.
  collection.sort(sortByStringdesc);
  collection.records.forEach((f) => print(f.item));

  collection.clearSorters();

  ///
  /// Configuration for sorting.
  ///
  /// The sorting is not stable, which means, the indexes of "equal" elements could be
  /// juggled.
  ///
  ///
  var sorter = {
    "caseSensitive": false,
    "direction": "desc",
    "enabled": true,
    "property": ''
  };

  print("Case insensitive sort - config.");
  collection.sort(sorter);
  collection.records.forEach((f) => print(f.item));
}

```
