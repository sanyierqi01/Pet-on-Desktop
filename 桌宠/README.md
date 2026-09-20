# 桌面宠物

这是一个不依赖联网和第三方运行库的 Windows 桌面宠物。身体和人脸使用独立图层，默认人脸来自原照片；可以在人脸管理程序中上传其他照片，离线识别并替换桌宠人脸。

## 启动

双击 `桌面宠物.exe` 启动桌宠。右键桌宠并选择“人脸管理”，即可在同一个程序中上传、切换或删除人脸。

第一次使用时也可以运行 `创建快捷方式.cmd`，把统一的“桌宠”入口放到桌面和开始菜单。

分享给其他电脑时，直接发送 `release\桌宠-便携版.zip`。对方解压后双击 `桌面宠物.exe` 即可，不需要安装 PowerShell 7、Python、OpenCV 或其他开发工具。

`桌面宠物.exe` 会防止重复启动，并让 PowerShell 后台运行；如果桌宠脚本出错，会弹出错误提示。需要查看控制台输出时，可改用 `start-pet.cmd`。

也可以在当前目录运行：

```powershell
pwsh.exe -NoProfile -ExecutionPolicy Bypass -STA -File .\desktop-pet.ps1
```

## 操作

- 左键拖动：移动角色。
- 屏幕边界：拖动或自动爬行时，角色始终限制在当前显示器的工作区内。
- 单击角色：让它跳一下，并说“宝宝，我爱你”。
- 自动爬行：角色持续朝鼠标方向移动，并根据鼠标位置左右转身。
- 四足步态：前爪和后腿按对角节奏交替前伸、撑地、抬起并回收，头肩同步做前后重心转移。
- 疲劳提醒：4 秒内切换方向达到 4 次时，会说“宝宝，我累了”，露出半闭眼、垂眉、叹气嘴和汗滴组成的疲惫表情，并暂停爬行 3 秒；8 秒内不会重复提醒。
- 右键角色：打开菜单，可暂停自动爬行、切换始终置顶、设置开机启动或退出。
- 人脸管理：“上传照片”会自动检测人脸、裁切并设为当前人脸；“删除”不会影响默认人脸。

## 文件

- `assets/portrait-source.jpg`：项目内保留的原照片。
- `assets/head-cutout.png`：自动提取的透明头部素材。
- `assets/faces/default.png`：默认人脸。
- `assets/faces/library.json`：人脸库和当前选择。
- `assets/layers/body.png`：独立的透明身体层。
- `assets/layers/face.png`：独立的透明人脸层。
- `assets/pet-preview.png`：桌宠静态预览。
- `scripts/build-assets.ps1`：重新生成透明头部素材。
- `scripts/detect-face.ps1`：使用 Windows 离线人脸检测。
- `scripts/face-library.ps1`：人脸入库、切换、删除和当前人脸读取。
- `scripts/build-launcher.ps1`：重新生成带图标的统一启动程序。
- `scripts/install-shortcuts.ps1`：创建桌面和开始菜单快捷方式。
- `scripts/build-release.ps1`：生成可直接分享的便携压缩包。
- `ui/face-manager.xaml`：人脸管理界面。

如需恢复默认人脸，在人脸管理中选中“默认人脸”并点击“设为当前”。
