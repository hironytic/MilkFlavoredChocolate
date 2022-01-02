//
// HelloSwiftMainWindow.swift
// SampleHelloSwift
//
// Copyright (c) 2022 Hironori Ichimiya <hiron@hironytic.com>
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
import MilkFlavoredChocolate

func LOWORD(_ wParam: WPARAM) -> WORD {
  return WORD(wParam)
}

func HIWORD(_ wParam: WPARAM) -> WORD {
  return WORD((DWORD(wParam) >> 16) & 0xffff)
}

final class HelloSwiftMainWindow: Window {
  let sayButtonId = WORD(100)
  var hWndSayButton: HWND!

  static func create() throws -> Self {
    return try! create(
      windowName: "Hello! Swift!!",
      dwStyle: UInt32(WS_OVERLAPPEDWINDOW),
      x: CW_USEDEFAULT,
      y: CW_USEDEFAULT,
      nWidth: 300,
      nHeight: 200,
      hWndParent: nil,
      hMenu: nil
    )
  }

  override func windowProc(_ hWnd: HWND, _ uMsg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
    switch Int32(uMsg) {
      case WM_CREATE:
        return onCreate(hWnd, uMsg, wParam, lParam)

      case WM_DESTROY:
        return onDestroy(hWnd, uMsg, wParam, lParam)
      
      case WM_COMMAND:
        return onCommand(hWnd, uMsg, wParam, lParam)
      
      default:
        return super.windowProc(hWnd, uMsg, wParam, lParam)
    }
  }

  private func onCreate(_ hWnd: HWND, _ uMsg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
    let result = super.windowProc(hWnd, uMsg, wParam, lParam)
    guard result != -1 else { return result }

    hWndSayButton = CreateWindowExW(0, WC_BUTTON.toWchars(), "Say".toWchars(),
        DWORD(WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON),
        8, 8, 80, 32,
        hWnd,
        UnsafeMutablePointer.init(bitPattern: UInt(sayButtonId)),
        Application.shared.hInstance, nil)

    return result
  }

  private func onDestroy(_ hWnd: HWND, _ uMsg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
    PostQuitMessage(0)
    return 0
  }

  private func onCommand(_ hWnd: HWND, _ uMsg: UINT, _ wParam: WPARAM, _ lParam: LPARAM) -> LRESULT {
    let controlId = LOWORD(wParam)
    switch controlId {
    case sayButtonId:
      MessageBoxW(hWnd, "Hello".toWchars(), "To Swift".toWchars(), UINT(MB_OK))
      return 0
    
    default:
      return super.windowProc(hWnd, uMsg, wParam, lParam)
    }
  }
}
