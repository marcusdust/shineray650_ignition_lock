# 鑫源650电门锁

该电门锁基于合宙esp32c3开发板开发，用esp32c3控制两路继电器，分别控制点火线和熄火线。
软件环境为[LuatOS](https://wiki.luatos.com/index.html)。

## 环境安装
1. 首先安装LutOS开发环境；
2. 参考[esp32c3 LuatOS](https://wiki.luatos.com/chips/esp32c3/board.html)开发教程；

## 硬件需求
1. 合宙esp32c3开发板一块；
2. 继电器两路，最好是磁保持继电器；
3. 按键开关一个，输密码用；
4. 4pin和2pin接头若干，导线若干；
5. 12v转5v电源板一块。

## 使用教程
熄火线pin18，电源线pin19，可以自己在代码中修改pin脚定于i。
   * 钥匙开状态：熄火线断开，电源线接通
   * 钥匙关状态：熄火线搭铁，电源线断开

按键为pin9，短按表示输入0，长按（超过500ms）为1.
turn_on_pwd为开锁密码，turn_off_pwd为关锁密码，密码值需自行修改，只支持二进制密码。

