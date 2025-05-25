# ✅ Boss Brawler 用戶管理快速設置檢查清單

## 已完成的步驟 ✅

- [x] 添加 Firebase Auth 和 Google Sign-In 依賴到 `pubspec.yaml`
- [x] 創建 `AuthService` - 完整的認證邏輯
- [x] 創建 `AuthScreen` - 現代化認證 UI
- [x] 修改 `main.dart` - 整合認證流程和 `AuthWrapper`
- [x] 解決 CocoaPods 依賴問題
- [x] 清理並重新安裝 Flutter 依賴

## 下一步：Firebase Console 配置 🔧

### 1. 啟用 Authentication (5 分鐘)
前往 [Firebase Console](https://console.firebase.google.com) > boss-brawler 專案

1. **點擊左側選單 "Authentication"**
2. **選擇 "Sign-in method" 標籤**
3. **啟用以下提供商：**
   - ✅ **Anonymous** - 點擊啟用
   - ✅ **Google** - 點擊編輯，輸入支援電子郵件，保存

### 2. 設置 Firestore 安全規則 (2 分鐘)
前往 Firebase Console > Firestore Database > Rules

暫時使用以下測試規則：
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read/write their own chat sessions
    match /chats/{userId}/sessions/{sessionId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. 測試應用 (5 分鐘)

```bash
flutter run
```

**預期行為：**
- 🎯 看到認證畫面（黑色漸層背景，Boss Brawler logo）
- ⚡ "Quick Trial" 按鈕可點擊（匿名登入）
- 🔗 "Continue with Google" 按鈕可點擊
- 📱 成功登入後會跳轉到主畫面

### 4. 驗證數據儲存 (3 分鐘)

登入後檢查 Firebase Console > Firestore：

應該會看到新的文檔結構：
```
users/{generatedUserId}
  ├── profile
  │   ├── name: "User" (匿名) 或 Google 用戶名
  │   ├── email: null (匿名) 或 Google 郵箱
  │   ├── avatar: null (匿名) 或 Google 頭像
  │   ├── createdAt: timestamp
  │   └── isAnonymous: true/false
  ├── settings
  │   ├── theme: "dark"
  │   ├── notifications: true
  │   └── privacy: "private"
  └── metadata
      ├── totalSessions: 0
      └── lastActive: timestamp
```

## 疑難排除 🐛

### 問題：Google 登入失敗
**解決方案：**
```bash
# 獲取 SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```
將顯示的 SHA-1 添加到 Firebase Console > Project Settings > Your apps > Android app

### 問題：匿名登入失敗
**檢查：** Firebase Console > Authentication > Sign-in method > Anonymous 是否已啟用

### 問題：Firestore 權限錯誤
**檢查：** 確認上述安全規則已正確設置

## 成功指標 🎯

- [ ] 匿名登入可正常工作
- [ ] Google 登入可正常工作  
- [ ] 用戶資料正確儲存到 Firestore
- [ ] 應用可以正常切換到主畫面
- [ ] 沒有控制台錯誤

## 下一階段預覽 🚀

完成基礎設置後，我們將進行：

1. **整合現有聊天系統** - 讓聊天記錄與用戶帳戶關聯
2. **添加用戶狀態顯示** - 在主畫面顯示用戶資訊
3. **實作帳戶升級流程** - 讓匿名用戶可以升級為完整帳戶
4. **雲端同步** - 跨設備資料同步

## 需要幫助？

如果遇到問題，請：
1. 檢查 Firebase 專案配置
2. 確認網絡連接
3. 查看 Flutter 控制台錯誤訊息
4. 檢查 Firebase Console 中的錯誤日誌 