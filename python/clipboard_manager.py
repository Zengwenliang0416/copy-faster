from pynput import keyboard as pynput_keyboard
from pynput.keyboard import Key, Controller
import pyperclip
import time

class ClipboardManager:
    def __init__(self):
        self.texts = self.load_texts_from_file()
        self.current_index = 0
        self.shift_pressed = False
        self.keyboard = Controller()
    
    def load_texts_from_file(self):
        """从文件中加载文本"""
        try:
            with open('texts.txt', 'r', encoding='utf-8') as file:
                return [line.strip() for line in file if line.strip()]
        except FileNotFoundError:
            print("错误：未找到 texts.txt 文件。请确保文件存在于正确的位置。")
            return []
        except Exception as e:
            print(f"读取文件时发生错误: {e}")
            return []
    
    def paste_text(self, text):
        """使用键盘控制器模拟Command+V"""
        pyperclip.copy(text)
        time.sleep(0.1)  # 等待复制完成
        self.keyboard.press(Key.cmd)
        self.keyboard.press('v')
        self.keyboard.release('v')
        self.keyboard.release(Key.cmd)
    
    def on_press(self, key):
        if key == pynput_keyboard.Key.shift:
            if not self.shift_pressed:
                self.shift_pressed = True
                if self.texts:
                    text = self.texts[self.current_index]
                    # 执行粘贴
                    self.paste_text(text)
                    print(f"\n已粘贴: {text}")
                    # 更新索引，循环访问文本
                    self.current_index = (self.current_index + 1) % len(self.texts)
    
    def on_release(self, key):
        if key == pynput_keyboard.Key.shift:
            self.shift_pressed = False
        elif key == pynput_keyboard.Key.esc:
            # 按ESC键退出程序
            return False
    
    def run(self):
        if not self.texts:
            print("没有可用的文本。请检查 texts.txt 文件。")
            return

        print("程序已启动！")
        print("从文件中读取的文本内容：")
        for i, text in enumerate(self.texts, 1):
            print(f"第 {i} 行: {text}")
        print("\n按Shift键来粘贴这些文本，按ESC退出程序。")
        print("注意：请确保已授予终端辅助功能权限")
        
        # 开始监听键盘事件
        with pynput_keyboard.Listener(on_press=self.on_press, on_release=self.on_release) as listener:
            listener.join()

if __name__ == "__main__":
    manager = ClipboardManager()
    manager.run()
