## データ処理層（CRUD操作、フォーム処理 等）

### 必須チェック項目：

- **v-model の適切な使用**: v-modelでbindしているものを、その仕組みの外で変更していないか
- **フォーム処理**: バリデーション、送信処理、エラーハンドリングが適切に実装されているか
- **ストア連携**: 非同期処理の適切な実装とローディング状態の管理
- **エラーハンドリング**: 適切なHTTPステータスコードとユーザーフレンドリーなエラーメッセージ

### パフォーマンス考慮点：

- 不要な計算処理の削除（既存実装パターンを参考に）
- バッチ処理での効率的なデータ操作

### 設計・命名規則：

- 暗黙的な処理の回避（currentConversation == undefined などのstate依存を避ける）
- 情報量のないコメントは削除
- 特殊な実装には必ずコメントで理由を明記

### データ操作パターン：

#### 1. ダイアログ実装パターン

```vue
<script setup lang="ts">
// 状態管理
const dialogVisible = ref(false)
const formData = ref({ /* 初期値 */ })

// ダイアログ操作
function openDialog() {
  dialogVisible.value = true
}

function closeDialog() {
  dialogVisible.value = false
  formData.value = { /* 初期値にリセット */ }
}

// データ操作
function handleSubmit() {
  if (!validateForm()) return

  store.someAction(formData.value).then(() => {
    closeDialog()
    // 必要に応じてリストの再読み込み
  })
}
</script>
```

#### 2. CRUD操作パターン

```typescript
// 新規作成
function handleCreate() {
  store.createItem(createForm.value).then(() => {
    closeCreateDialog()
  })
}

// 更新
function handleUpdate() {
  store.updateItem(updateForm.value).then(() => {
    closeUpdateDialog()
  })
}

// 削除
function handleDelete(itemId: number) {
  ElMessageBox.confirm('この処理は取り消せません。実行しますか？', '削除する', {
    confirmButtonText: 'OK',
    cancelButtonText: 'キャンセル',
    type: 'warning'
  }).then(() => {
    store.deleteItem(itemId).then(() => {
      // リストの再読み込み
    })
  })
}
```

#### ❌ Bad - v-modelの仕組みの外での変更

```typescript
function onSwitchIncludeOutdated(v: string | number | boolean) {
  getProductsQuery.value = { ...getProductsQuery.value, includeOutdated: v === true }
}
```

### レビュー対象外：

以下はデータ処理層ではなく、他の層でレビューすること：

- **型定義の基本設計** → モデリング層で扱う
- **ページの基本構造** → プロトタイピング層で扱う
- **基本的なデータ表示** → 表示・スタイリング層で扱う
- **静的なスタイリング** → 表示・スタイリング層で扱う
