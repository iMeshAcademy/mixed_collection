part of mixed_collection;
// Copyright (c) 2019, iMeshAcademy authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// MIT-style license that can be found in the LICENSE file.

/// Class which define database error.
/// This can be extended in future to provide additional functionalities.
class CollectionError {
  final String operation;
  final String reason;
  final Object data;

  CollectionError(this.operation, this.reason, this.data);
}
