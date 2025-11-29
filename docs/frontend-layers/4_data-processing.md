## データ処理層（CRUD操作、フォーム処理 等）

### 必須チェック項目：

- **v-model の適切な使用**: v-modelでbindしているものを、その仕組みの外で変更していないか
- **フォーム処理**: バリデーション、送信処理、エラーハンドリングが適切に実装されているか
- **ストア呼び出し**: コンポーネントからストアのactionsを適切に呼び出しているか（ストアの実装自体は見ない）
- **エラーハンドリング**: ユーザーフレンドリーなエラーメッセージの表示と適切なフィードバック

### View側の状態管理

#### 設計哲学

- **「コストと効果の天秤」**: 全てに完璧なloading表示を実装するのではなく、リソースの規模に応じて判断する。小さいリソースにはloading表示自体を諦める選択肢もある
- **「暗黙的な状態」の優先**: `loading = true/false`を明示的に管理するより、データの有無（例: `paginationStats`がnullかどうか）で判定する方が不整合が起きにくい

#### レビュー観点

- **loading状態の必要性**: 本当にloading表示が必要か。小さいリソースで状態管理のコストに見合うか
- **状態の判定方法**: 明示的な`loading`フラグより、データの有無で判定できないか
- **try-catchの必要性**: Store側で既にエラーハンドリングしている場合、View側でのtry-catchは冗長でないか

#### レビュー対象外

- **Store内のloading状態の実装** → モデリング層で扱う（そもそもStoreにloading状態を持たせない方針）
- **loading中のUI表示（スピナー等）** → 表示・スタイリング層で扱う

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

### レビュー対象外

以下はデータ処理層ではなく、他の層でレビューすること：

- **型定義の基本設計** → モデリング層で扱う
- **ストアの実装詳細（axios呼び出し、state更新ロジック）** → モデリング層で扱う
- **APIレスポンスの型定義** → モデリング層で扱う
- **HTTPステータスコードの処理ロジック** → モデリング層で扱う（ストアのcatch句）
- **ページの基本構造** → プロトタイピング層で扱う
- **基本的なデータ表示** → 表示・スタイリング層で扱う
- **静的なスタイリング** → 表示・スタイリング層で扱う
