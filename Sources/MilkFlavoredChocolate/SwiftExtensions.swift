//
// SwiftExtensions.swift
// MilkFlavoredChocolate
//
// Copyright (c) 2021 Hironori Ichimiya <hiron@hironytic.com>
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

import WinSDK

extension String {
  public init(from wchars: [WCHAR]) {
    self = wchars.withUnsafeBufferPointer {
      return String(decodingCString: $0.baseAddress!, as: UTF16.self)
    }
  }

  public var wide: [WCHAR] {
    return withCString(encodedAs: UTF16.self) { buf in
      [WCHAR](unsafeUninitializedCapacity: utf16.count + 1) { (outBuffer, initializedCount) in
        wcscpy_s(outBuffer.baseAddress, outBuffer.count, buf)
        initializedCount = outBuffer.count
      }
    }
  }
}

extension Array where Element == WCHAR {
  public func withUnsafeLPCWSTR<Result>(_ body: (LPCWSTR?) throws -> Result) rethrows -> Result {
    return try withUnsafeBufferPointer { try body($0.baseAddress) }
  }
}

extension Optional where Wrapped == Array<WCHAR> {
  public func withUnsafeLPCWSTR<Result>(_ body: (LPCWSTR?) throws -> Result) rethrows -> Result {
    if let wrapped = self {
      return try wrapped.withUnsafeLPCWSTR(body)
    } else {
      return try body(nil)
    }
  }
}
