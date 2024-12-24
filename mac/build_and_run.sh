#!/bin/bash

echo "正在编译..."
swiftc -framework Cocoa -framework Carbon clipboard_monitor.swift -o clipboard_paste

if [ $? -eq 0 ]; then
    echo "编译成功！"
    echo "注意：首次运行时需要授予辅助功能权限"
    echo "1. 打开系统偏好设置"
    echo "2. 进入隐私与安全性 > 辅助功能"
    echo "3. 点击左下角的锁图标解锁"
    echo "4. 找到并勾选终端（Terminal）"
    echo -e "\n按回车键继续..."
    read
    
    # 运行程序
    ./clipboard_paste
else
    echo "编译失败！"
fi