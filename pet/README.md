# 桌面宠物

这是一个不依赖联网和第三方运行库的 Windows 桌面宠物。它把原照片中的头部提取为透明素材，再组合成穿原款浅蓝衬衫和深色长裤的四足跪撑 Q 版造型。

## 启动

双击 `桌面宠物.exe`。第一次使用时也可以运行 `创建快捷方式.cmd`，把“桌宠”放到桌面和开始菜单。

`桌面宠物.exe` 会防止重复启动，并让 PowerShell 后台运行；如果桌宠脚本出错，会弹出错误提示。需要查看控制台输出时，可改用 `start-pet.cmd`。

也可以在当前目录运行：

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\desktop-pet.ps1
```

## 操作

- 左键拖动：移动角色。
- 单击角色：让它跳一下，并说“宝宝，我爱你”。
- 自动爬行：角色持续朝鼠标方向移动，并根据鼠标位置左右转身。
- 四足步态：前爪和后腿按对角节奏交替前伸、撑地、抬起并回收，头肩同步做前后重心转移。
- 疲劳提醒：4 秒内切换方向达到 4 次时，会说“宝宝，我累了”，露出半闭眼、垂眉、叹气嘴和汗滴组成的疲惫表情，并暂停爬行 3 秒；8 秒内不会重复提醒。
- 右键角色：打开菜单，可暂停自动爬行、切换始终置顶、设置开机启动或退出。

## 文件

- `assets/portrait-source.jpg`：项目内保留的原照片。
- `assets/head-cutout.png`：自动提取的透明头部素材。
- `assets/pet-preview.png`：桌宠静态预览。
- `scripts/build-assets.ps1`：重新生成透明头部素材。
- `scripts/build-launcher.ps1`：重新生成带图标的启动程序。
- `scripts/install-shortcuts.ps1`：创建桌面和开始菜单快捷方式。

如更换原照片，把新照片保存为 `assets/portrait-source.jpg`，删除 `assets/head-cutout.png`，再启动桌宠即可自动重建。
