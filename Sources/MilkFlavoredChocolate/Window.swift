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

import WinSDK

public enum MFCError: Error {
  case registerClassError
  case createWindowError
}

private var windowMap: [HWND: Window] = [:]
private var windowClassMap: [String: ATOM] = [:]

public enum WindowClassRegistrar {
  public static func registerClass(
    style: UINT,
    cbClsExtra: Int32,
    cbWndExtra: Int32,
    hInstance: HINSTANCE = Application.shared.hInstance,
    hIcon: HICON?,
    hCursor: HCURSOR?,
    hbrBackground: HBRUSH?,
    menuName: String?,
    className: String,
    hIconSm: HICON?    
  ) throws -> ATOM
  {
    let atomOrNil: ATOM? = (menuName?.toWchars()).withUnsafeLPCWSTR { lpszMenuName in
      className.toWchars().withUnsafeLPCWSTR { lpszClassName in
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
        return RegisterClassExW(&wc)      
      }
    }

    guard let atom = atomOrNil else { throw MFCError.registerClassError }
    windowClassMap[className] = atom
    return atom
  }

  public static func search(for className: String) -> ATOM? {
    return windowClassMap[className]
  }
}

open class Window {
  public var hWnd: HWND?

  public required init(hWnd: HWND) {
    self.hWnd = hWnd
  }

  open class var windowClassName: String { preconditionFailure("Please override this property") }
  
  open class func registerClass() throws -> ATOM { preconditionFailure("Please override this property") }

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
    let atom = try WindowClassRegistrar.search(for: windowClassName) ?? registerClass()

    var result: Self? = nil
    let factory = WindowFactory { hWnd in
      let created = Self.init(hWnd: hWnd)
      result = created
      return created
    }
    let lpParam = Unmanaged<WindowFactory>.passUnretained(factory).toOpaque()

    let hWnd = CreateWindowExW(
      dwExStyle,
      UnsafePointer(bitPattern: UInt(atom)),
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
      throw MFCError.createWindowError
    }

    if let ret = result {
      return ret
    } else {
      throw MFCError.createWindowError
    }
  }

  open func wndProc(_ hWnd: HWND, _ uMsg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
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
      window = factory.factory(hWnd)
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
    result = window.wndProc(hWnd, uMsg, wParam, lParam)
    if isNCDestroy {
      window.hWnd = nil
    }
  } else {
    result = DefWindowProcW(hWnd, uMsg, wParam, lParam)
  }

  return result
}

private class WindowFactory {
  let factory: (HWND) -> Window
  init(factory: @escaping (HWND) -> Window) {
    self.factory = factory
  }
}
