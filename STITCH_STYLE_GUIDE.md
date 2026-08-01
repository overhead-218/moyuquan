# 摸鱼圈 · Stitch 风格设计规范（Material 3 Expressive）

Google Stitch 产出的视觉语言即 Material 3 Expressive。本项目所有页面按此规范统一视觉。

## 色彩
- 主色 Primary: `#0A7C74`
  - Primary Light: `#148F86`
  - Primary Dark: `#075C56`
  - Primary Surface（极浅青底）: `#E6F2F0`
- 背景 Background: `#F7F3EE`（暖白）
- 卡片 Card: `#FFFFFF`
- 金色强调 Accent: `#C49A5E` / `#E0B670`
- 文字：主 `#1A1A1A` / 次 `#666666` / 弱 `#999999`
- 分隔 Divider: `#EDEAE3`
- 状态：喜欢/删除红 `#FF4757`，成功绿 `#2ECC71`

## 圆角 Radius
- 大卡：20 ｜ 中卡：16 ｜ 按钮/输入框：14 ｜ FAB：20（圆形用 circle）
- Chip/标签：全圆 999 ｜ 头像：圆形

## 间距 Spacing
- 页面水平 padding：20 ｜ 垂直：16–20
- 卡片间距 margin：16 ｜ 卡片内 padding：16–20
- 元素间距：8 / 12 ｜ 列表项点击区 ≥ 56（舒适 64–72）

## 阴影（柔和分层，用 withValues(alpha:)）
- sm：`0 2 8 rgba(0,0,0,0.04)`
- md：`0 4 16 rgba(0,0,0,0.06)`
- lg：`0 8 24 rgba(0,0,0,0.08)`

## 字体 Typography
- 大标题 Display：28, w800
- 标题 Title：22–24, w700
- 副标题 Subtitle：16–18, w600
- 正文 Body：14–15, w400
- 次要 Caption：12–13, w400
- 强调数字：大号粗体，金色或主色

## 层级 Hierarchy
- hero / 头部：渐变背景（主色或金色）+ 白字
- 内容卡：白底 + 柔和阴影 + 大圆角
- 强调块：大胆用色（会员金、等级金）
- 用留白区分区块，避免线框堆叠

## 动效 Motion（弹性）
- 曲线 `Curves.easeOutBack` / `elasticOut`，进入时长 250–400ms
- 保留现有心跳 / 呼吸 / 滑入动效，增强弹性感

## 底部导航（home_shell）
- 增高 NavigationBar，药丸指示器（选中项浅青底 + 主色图标）
- 图标 + 文字，选中加粗，保持 5 Tab

## 组件规范
- AppBar：标题 22 w700 主色，背景暖白，返回箭头主色
- 列表项 ListTile：左图标主色，标题 14–15，右 chevron 弱色
- 按钮：主按钮主色实心圆角 14；次按钮白底描边
- Chip：全圆，浅青底主色字
- FAB：圆角/圆形，金色渐变发光（沿用 animated_publish_button 风格并适配）

## 统一要求
- 所有颜色用 `const Color(0xFFxxxxxx)`
- `withValues(alpha:)` 替代 `withOpacity()`
- 无 TODO、无编译错误
- 保留现有页面结构、跳转逻辑（Navigator.push）、内部辅助组件，只优化视觉
