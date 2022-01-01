//
// Application.swift
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

import WinSDK

/// The base class of Windows application object.
open class Application {
  /// Handle to the current application instance.
  public let hInstance: HINSTANCE

  /// Initialize the object.
  public required init() {
    hInstance = GetModuleHandleW(nil)
  }

  private static var _shared: Application!

  /// The only `Application` instance.
  public static var shared: Self {
    return _shared as! Self
  }

  /// Entry point of application.
  open class func main() {
    _shared = self.init()

    if (try? _shared.initInstance()) != nil {
      _shared.messageLoop()
    }
    _shared.exitInstance()
  }

  /// Initialize the application.
  /// For example, register a window class and construct
  /// a main window of the application.
  open func initInstance() throws {
  }

  /// Clean up the application when it terminates.
  open func exitInstance() {
  }

  /// Do a message loop.
  open func messageLoop() {
    var msg = MSG()
    while GetMessageW(&msg, nil, 0, 0) {
      TranslateMessage(&msg)
      DispatchMessageW(&msg)
    }
  }
}
