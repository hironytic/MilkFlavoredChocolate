//
// Window.swift
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

private var windowMap: [HWND: Window] = [:]
private var windowClassMap: [String: WindowClassRegistrar.Registration] = [:]

/// Functions about ragistration of window class.
public enum WindowClassRegistrar {
  /// The result of the registration.
  public struct Registration {
    internal var atom: ATOM
    internal init(atom: ATOM) {
      self.atom = atom
    }
  }

  /// Register window class.
  /// - Parameters:
  ///   - style: The class styles.
  ///   - cbClsExtra: The number of extra bytes to allocate following the window-class structure.
  ///   - cbWndExtra: The number of extra bytes to allocate following the window instance.
  ///   - hInstance: A handle to the instance that contains the window procedure for the class.
  ///   - hIcon: A handle to the class icon.
  ///   - hCursor: A handle to the class cursor.
  ///   - hbrBackground: A handle to the class background brush.
  ///   - menuName: The resource name of the class menu.
  ///   - className: A window class name.
  ///   - hIconSm: A handle to a small icon that is associated with the window class.
  /// - Returns: The result of the registration.
  public static func registerClass(
    style: UINT,
    cbClsExtra: Int32 = 0,
    cbWndExtra: Int32 = 0,
    hInstance: HINSTANCE = Application.shared.hInstance,
    hIcon: HICON?,
    hCursor: HCURSOR?,
    hbrBackground: HBRUSH?,
    menuName: String?,
    className: String,
    hIconSm: HICON?
  ) throws -> Registration
  {
    let atom: ATOM = try (menuName?.toWchars()).withUnsafeLPCWSTR { lpszMenuName in
      return try className.toWchars().withUnsafeLPCWSTR { lpszClassName in
        var wc = WNDCLASSEXW( cbSize: UINT(MemoryLayout<WNDCLASSEXW>.size),
                              style: style,
                              lpfnWndProc: mfcWindowProc,
                              cbClsExtra: cbClsExtra,
                              cbWndExtra: cbWndExtra,
                              hInstance: hInstance,
                              hIcon: hIcon,
                              hCursor: hCursor,
                              hbrBackground: hbrBackground,
                              lpszMenuName: lpszMenuName,
                              lpszClassName: lpszClassName,
                              hIconSm: hIconSm)
        let atom = RegisterClassExW(&wc)
        if atom == 0 {
          throw MFCError.registerClassError(GetLastError())
        }
        return atom
      }
    }

    let registration = Registration(atom: atom)
    windowClassMap[className] = registration
    return registration
  }

  /// Search for window class registration.
  /// - Parameter className: A window class name.
  /// - Returns: Result of registration, or `nil` when it is not registered.
  public static func search(for className: String) -> Registration? {
    return windowClassMap[className]
  }
}

/// The base class of a window.
open class Window {
  /// The window handle.
  public var hWnd: HWND?

  /// Initializes the object
  /// - Parameter hWnd: The window handle of the window.
  public required init(hWnd: HWND) {
    self.hWnd = hWnd
  }

  /// The name of window class.
  ///
  /// The default implementation uses `NSStringFromClass(self)`.
  /// You can change this behavior by overriding this class method.
  open class var windowClassName: String {
    return NSStringFromClass(self)
  }
  
  /// Register its window class.
  /// - Returns: The result of registration.
  /// 
  /// The default implementation uses parameters below.
  /// You can change this behavior by overriding this class method.
  /// 
  /// ```swift
  /// func registerClass() throws -> WindowClassRegistrar.Registration {
  ///   return try WindowClassRegistrar.registerClass(
  ///     style: UINT(CS_HREDRAW | CS_VREDRAW),
  ///     hIcon: nil,
  ///     hCursor: nil,
  ///     hbrBackground: nil,
  ///     menuName: nil,
  ///     className: windowClassName,
  ///     hIconSm: nil
  ///   )
  /// }
  /// ```
  open class func registerClass() throws -> WindowClassRegistrar.Registration {
    return try WindowClassRegistrar.registerClass(
      style: UINT(CS_HREDRAW | CS_VREDRAW),
      hIcon: nil,
      hCursor: nil,
      hbrBackground: nil,
      menuName: nil,
      className: windowClassName,
      hIconSm: nil
    )
  }

  /// Creates a window.
  /// - Parameters:
  ///   - dwExStyle: The extended window style of the window being created.
  ///   - windowName: The window name.
  ///   - dwStyle: The style of the window being created.
  ///   - x: The initial horizontal position of the window.
  ///   - y: The initial vertical position of the window
  ///   - nWidth: The width, in device units, of the window.
  ///   - nHeight: The height, in device units, of the window.
  ///   - hWndParent: A handle to the parent or owner window of the window being created.
  ///   - hMenu: A handle to a menu.
  ///   - hInstance: A handle to the instance of the module to be associated with the window.
  /// - Returns: The created window object.
  public static func create(
    dwExStyle: DWORD = 0,
    windowName: String,
    dwStyle: DWORD,
    x: Int32,
    y: Int32,
    nWidth: Int32,
    nHeight: Int32,
    hWndParent: HWND?,
    hMenu: HMENU?,
    hInstance: HINSTANCE = Application.shared.hInstance
  ) throws -> Self {
    let registration = try WindowClassRegistrar.search(for: windowClassName) ?? registerClass()

    let factory = TypedWindowFactory<Self>()
    let lpParam = Unmanaged<WindowFactory>.passUnretained(factory).toOpaque()

    let hWnd = CreateWindowExW(
      dwExStyle,
      UnsafePointer(bitPattern: UInt(registration.atom)),
      windowName.toWchars(),
      dwStyle,
      x,
      y,
      nWidth,
      nHeight,
      hWndParent,
      hMenu,
      hInstance,
      lpParam
    )
    if hWnd == nil {
      throw MFCError.createWindowError(GetLastError())
    }

    if let window = factory.window {
      return window
    } else {
      throw MFCError.createWindowError(0)
    }
  }

  /// Window procedure.
  /// - Parameters:
  ///   - uMsg: The message.
  ///   - wParam: Additional message information.
  //    - lParam: Additional message information.
  /// - Returns: The return value is the result of the message processing.
  ///
  /// You can handle messages sent to this window by overriding this method.
  open func windowProc(_ uMsg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
    return DefWindowProcW(hWnd, uMsg, wParam, lParam)
  }
}

private func mfcWindowProc(hWnd: HWND?, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT {
  guard let hWnd = hWnd else { return DefWindowProcW(hWnd, uMsg, wParam, lParam) }

  var isNCDestroy = false
  let window: Window?
  switch Int32(uMsg) {
  case WM_NCCREATE:
    let lpCreateStruct: UnsafePointer<CREATESTRUCTW>? = UnsafePointer(bitPattern: Int(lParam))
    if let lpCreateParams = lpCreateStruct?.pointee.lpCreateParams {
      let factory = Unmanaged<WindowFactory>.fromOpaque(lpCreateParams).takeUnretainedValue()
      window = factory.create(hWnd: hWnd)
      windowMap[hWnd] = window
    } else {
      window = nil
    }
  
  case WM_NCDESTROY:
    window = windowMap[hWnd]
    windowMap[hWnd] = nil
    isNCDestroy = true

  default:
    window = windowMap[hWnd]
  }

  let result: LRESULT
  if let window = window {
    result = window.windowProc(uMsg, wParam, lParam)
    if isNCDestroy {
      window.hWnd = nil
    }
  } else {
    result = DefWindowProcW(hWnd, uMsg, wParam, lParam)
  }

  return result
}

private class WindowFactory {
  func create(hWnd: HWND) -> Window {
    preconditionFailure()
  }
}

private class TypedWindowFactory<W: Window>: WindowFactory {
  var window: W? = nil
  override func create(hWnd: HWND) -> Window {
    let window = W.init(hWnd: hWnd)
    self.window = window
    return window
  }
}
