# 旅遊App配色方案更新總結

## 🎨 新的配色方案

### 淺色主題 (Light Theme)
- **主色調**: `#4A90E2` (溫暖藍色)
- **輔助色**: `#6BB6FF` (較亮的溫暖藍色)
- **背景色**: `#F8FAFC` (非常淺的灰藍色)
- **卡片背景**: `#FFFFFF` (純白色)
- **輸入框背景**: `#F9FAFB` (極淺灰色)

### 深色主題 (Dark Theme)
- **主色調**: `#6BB6FF` (較亮的溫暖藍色)
- **輔助色**: `#4A90E2` (溫暖藍色)
- **背景色**: `#121212` (深灰色)
- **卡片背景**: `#1E293B` (深藍灰色)
- **輸入框背景**: `#334155` (中等深度的灰藍色)

## 🎯 配色理念

### 旅遊App特色
1. **溫暖舒適**: 採用溫暖的藍色系，營造放鬆的旅行氛圍
2. **清新自然**: 淺色背景配合藍色主題，給人清新自然的感覺
3. **專業可靠**: 藍色系給人信任感和專業感，適合票務預訂
4. **視覺舒適**: 柔和的色彩搭配，長時間使用不會造成視覺疲勞

### 漸變效果
- **主頁背景**: 使用多層次藍灰色漸變，營造深度感
- **AppBar**: 溫暖藍色漸變，突出品牌特色
- **底部導航**: 微妙的漸變效果，增強層次感

## 🚀 如何查看效果

### 運行App
```bash
cd ktv_bts
flutter run
```

### 切換主題
1. 打開App設置頁面
2. 在主題選項中切換淺色/深色模式
3. 查看不同主題下的配色效果

## 📱 適配說明

### 已更新的組件
- ✅ 主題配色 (ThemeData)
- ✅ 按鈕樣式 (ElevatedButton, OutlinedButton)
- ✅ 輸入框樣式 (InputDecoration)
- ✅ 卡片樣式 (Card)
- ✅ 導航欄配色 (AppBar, BottomNavigationBar)
- ✅ 對話框樣式 (Dialog, SnackBar)
- ✅ 選擇器樣式 (Radio, Checkbox)

### 視覺效果
- 更溫馨舒適的整體氛圍
- 更適合旅遊App的品牌形象
- 更好的用戶體驗和視覺舒適度
- 保持Material Design 3的現代感

## 🔧 技術細節

### 色彩值
```dart
// 主要色彩
static const Color primaryBlue = Color(0xFF4A90E2);
static const Color lightBlue = Color(0xFF6BB6FF);
static const Color backgroundLight = Color(0xFFF8FAFC);
static const Color backgroundDark = Color(0xFF121212);
static const Color cardDark = Color(0xFF1E293B);
```

### 漸變配色
- 淺色主題: 從淺灰藍到中等灰藍的漸變
- 深色主題: 從深藍灰到淺藍灰的漸變
- AppBar: 溫暖藍色的三色漸變

這個配色方案專為旅遊App設計，營造出輕鬆、舒適、可信賴的用戶體驗。
