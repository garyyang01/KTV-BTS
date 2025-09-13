# KTV BTS Payment Service Tests

這個目錄包含了 Stripe 支付服務的完整測試套件。

## 📁 測試檔案結構

```
test/
├── services/
│   ├── stripe_payment_service_test.dart          # 單元測試
│   └── stripe_payment_service_mock_test.dart     # Mock 測試
├── integration/
│   └── stripe_integration_test.dart              # 集成測試
├── test_config.dart                              # 測試配置
├── test_runner.dart                              # 測試運行器
└── README.md                                     # 本檔案
```

## 🚀 如何運行測試

### 1. 安裝依賴套件

```bash
flutter pub get
```

### 2. 生成 Mock 檔案

```bash
flutter packages pub run build_runner build
```

### 3. 運行所有測試

```bash
flutter test
```

### 4. 運行特定測試檔案

```bash
# 運行單元測試
flutter test test/services/stripe_payment_service_test.dart

# 運行 Mock 測試
flutter test test/services/stripe_payment_service_mock_test.dart

# 運行集成測試
flutter test test/integration/stripe_integration_test.dart
```

### 5. 運行測試並生成覆蓋率報告

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📋 測試類型說明

### 1. 單元測試 (Unit Tests)
- **檔案**: `stripe_payment_service_test.dart`
- **目的**: 測試個別方法和模型
- **包含**:
  - 服務初始化測試
  - PaymentRequest 模型測試
  - PaymentResponse 模型測試
  - 定價邏輯測試
  - 錯誤處理測試

### 2. Mock 測試 (Mock Tests)
- **檔案**: `stripe_payment_service_mock_test.dart`
- **目的**: 模擬 HTTP 請求測試 API 調用
- **包含**:
  - 成功創建支付意圖
  - API 錯誤處理
  - 網絡錯誤處理
  - 支付確認測試
  - 支付取消測試
  - 支付狀態查詢測試

### 3. 集成測試 (Integration Tests)
- **檔案**: `stripe_integration_test.dart`
- **目的**: 測試服務的整體功能
- **包含**:
  - 服務初始化集成測試
  - 支付請求驗證測試
  - 定價計算集成測試
  - 響應模型集成測試
  - 服務接口合規性測試

## 🔧 測試配置

### 環境變數
測試使用 `.env.test` 檔案，包含測試用的 API 金鑰：

```env
STRIPE_PUBLIC_KEY=pk_test_mock_public_key_for_testing
STRIPE_SECRET_KEY=sk_test_mock_secret_key_for_testing
ENVIRONMENT=test
```

### 測試數據
測試配置檔案 (`test_config.dart`) 包含：
- 測試常量
- 測試數據工廠
- 驗證函數

## 📊 測試覆蓋率

運行測試後，您可以查看覆蓋率報告：

```bash
flutter test --coverage
open coverage/html/index.html
```

## 🐛 調試測試

### 1. 運行單個測試
```bash
flutter test test/services/stripe_payment_service_test.dart --name "should create PaymentRequest with correct values"
```

### 2. 詳細輸出
```bash
flutter test --verbose
```

### 3. 調試模式
```bash
flutter test --debug
```

## 📝 添加新測試

### 1. 創建新的測試檔案
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Your Test Group', () {
    test('should do something', () {
      // Arrange
      // Act
      // Assert
    });
  });
}
```

### 2. 使用測試配置
```dart
import 'test_config.dart';

void main() {
  test('should use test config', () {
    final request = TestConfig.getAdultMorningRequest();
    expect(request.isAdult, isTrue);
  });
}
```

## ⚠️ 注意事項

1. **API 金鑰**: 測試使用模擬金鑰，不會發送真實的 API 請求
2. **環境變數**: 確保 `.env.test` 檔案存在
3. **Mock 生成**: 修改 Mock 測試後需要重新生成 Mock 檔案
4. **依賴更新**: 更新依賴套件後可能需要重新運行 `flutter pub get`

## 🔍 故障排除

### 常見問題

1. **Mock 檔案未生成**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **環境變數未載入**
   - 檢查 `.env.test` 檔案是否存在
   - 確認檔案路徑正確

3. **測試失敗**
   - 檢查測試輸出中的錯誤訊息
   - 確認所有依賴套件已安裝

4. **覆蓋率報告未生成**
   - 確保使用 `--coverage` 參數
   - 檢查 `coverage/` 目錄權限
