//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

#if os(Linux) && canImport(Synchronization)
import Synchronization
#else
import NIOConcurrencyHelpers
#endif

/// Provides locked access to `Value`.
///
/// On Linux this is backed by `Mutex` from the `Synchronization` module. On all other platforms, this type is backed by
/// `NIOLockedValueBox`.
@usableFromInline
internal struct LockedValueBox<Value: Sendable> {
    #if os(Linux) && canImport(Synchronization)
    @usableFromInline
    internal final class _Storage: Sendable {
        @usableFromInline
        internal let _mutex: Mutex<Value>

        @inlinable
        internal init(_ value: Value) {
            self._mutex = Mutex(value)
        }
    }

    @usableFromInline
    internal let _storage: _Storage

    /// Initialize the `Value`.
    @inlinable
    internal init(_ value: Value) {
        self._storage = _Storage(value)
    }

    /// Access the `Value`, allowing mutation of it.
    @inlinable
    internal func withLockedValue<T>(_ mutate: (inout Value) throws -> T) rethrows -> T {
        try self._storage._mutex.withLock { value in
            try mutate(&value)
        }
    }
    #else
    @usableFromInline
    internal let _storage: NIOLockedValueBox<Value>

    /// Initialize the `Value`.
    @inlinable
    internal init(_ value: Value) {
        self._storage = NIOLockedValueBox(value)
    }

    /// Access the `Value`, allowing mutation of it.
    @inlinable
    internal func withLockedValue<T>(_ mutate: (inout Value) throws -> T) rethrows -> T {
        try self._storage.withLockedValue(mutate)
    }
    #endif
}

extension LockedValueBox: Sendable {}
