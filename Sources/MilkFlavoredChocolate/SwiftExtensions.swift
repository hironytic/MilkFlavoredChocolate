//
// SwiftExtensions.swift
// MilkFlavoredChocolate
//
// Copyright (c) 2021,2022 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import WinSDK

extension String {
  /// Initialize a string from zero-terminated WCHAR array.
  /// - Parameter wchars: The array of WCHAR.
  public init(fromWchars wchars: [WCHAR]) {
    self = wchars.withUnsafeBufferPointer {
      return String(decodingCString: $0.baseAddress!, as: UTF16.self)
    }
  }

  /// Create zero-terminated WCHAR array from this string.
  /// - Returns: The array of WCHAR.
  public func toWchars() -> [WCHAR] {
    return withCString(encodedAs: UTF16.self) { buf in
      [WCHAR](unsafeUninitializedCapacity: utf16.count + 1) { (outBuffer, initializedCount) in
        wcscpy_s(outBuffer.baseAddress, outBuffer.count, buf)
        initializedCount = outBuffer.count
      }
    }
  }
}

extension Array where Element == WCHAR {
  /// Calls a closure with a pointer to a wchar string.
  /// - Parameter body: A closure with an LPCWSTR parameter.
  ///                   If it has a return value, that value is used as the return value
  ///                   of this function.
  public func withUnsafeLPCWSTR<Result>(_ body: (LPCWSTR?) throws -> Result) rethrows -> Result {
    return try withUnsafeBufferPointer { try body($0.baseAddress) }
  }
}

extension Optional where Wrapped == Array<WCHAR> {
  /// Calls a closure with a pointer to a wchar string.
  /// - Parameter body: A closure with an LPCWSTR parameter, or nil when the optional value itself is nil.
  ///                   If it has a return value, that value is used as the return value
  ///                   of this function.
  public func withUnsafeLPCWSTR<Result>(_ body: (LPCWSTR?) throws -> Result) rethrows -> Result {
    if let wrapped = self {
      return try wrapped.withUnsafeLPCWSTR(body)
    } else {
      return try body(nil)
    }
  }
}
