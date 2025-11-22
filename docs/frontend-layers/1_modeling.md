## モデリング層（型定義, ストア定義 等）

### レビュー前の確認事項

**実装意図の理解**

レビュー時は以下を自問してください:

1. **この変更は PR の目的を達成しているか?**
   - PR Description の「なぜやるか」と照らし合わせる

2. **実装された仕様は妥当か?**
   - オプショナル (`?`) の使用は仕様に基づいているか
   - 配列/オブジェクトの構造は API/仕様と一致しているか

3. **既存パターンに従っているか?**
   - 類似の機能の実装と比較
   - プロジェクト固有の慣習に従っているか

### 必須チェック項目

- **型定義の一貫性**: 既存の型定義を再利用し、新規型は必要最小限に抑えているか
- **API仕様との整合性**: APIレスポンスの型定義が正確で、エンドポイントとの対応が明確か
- **ストア設計の適切性**: 既存パターンに従い、state/actions/gettersが適切に設計されているか
- **エラーハンドリング**: すべてのaxiosリクエストに適切な`catch`処理が実装されているか

### ストア実装パターン：

#### 1. stateの定義

```typescript
type State = {
  games: Game[]
  games_stats: PaginationStats | null
  currentGame: Game | null
}
```

#### 2. actionsの実装パターン

```typescript
// 同期メソッド（UIロジックで必要でない場合）
getGames(query: GetGamesQuery = { page: 1, limit: 20 }) {
  axiosHotelLovers.get<GameResponseDto>('/games', { params: query })
    .then((response) => {
      this.games = response.data.items
      this.games_stats = response.data.meta
    })
    .catch((error) => {
      console.error('Failed to fetch games:', error)
    })
}

// Promiseを返すパターン（UIロジックで必要な場合）
updateGame(payload: UpdateGamePayload) {
  return new Promise<Game>((resolve, reject) => {
    axiosHotelLovers.put(`/games/${payload.id}`, payload)
      .then((res) => {
        // state更新
        resolve(res.data)
      })
      .catch((error) => {
        console.error('Failed to update game:', error)
        reject(error)
      })
  })
}
```

### パフォーマンス考慮点：

- 不要なAPI呼び出しの削減
- stateの適切な初期化と管理

### 設計・命名規則

- 型定義ファイル名は `{entity}.type.ts` 形式
- ストア名は `use{Entity}Store` 形式
- メソッド名は `get{Entity}`, `create{Entity}`, `update{Entity}`, `delete{Entity}` 形式

### Vue.js 型定義の特有の注意点

#### Emit 定義

```typescript
// ❌ 悪い例: 型安全でない
emit('append-input', message)

// ✅ 良い例: defineEmits で型定義
const emit = defineEmits<{
  'append-input': [message: string]
}>()
```

#### Props 定義

```typescript
// ❌ 悪い例: runtime のみの型定義
defineProps({
  items: Array
})

// ✅ 良い例: TypeScript 型定義
defineProps<{
  items: NextAction[]
}>()
```

#### Computed/Reactive の型推論

- computed の返り値型は明示的に指定しない（型推論に任せる）
- ref/reactive の型は初期値から推論できる場合は省略可能

```typescript
// ✅ 良い例
const count = ref(0) // number と推論される
const items = ref<NextAction[]>([]) // 空配列の場合は型指定必要
```

### レビューコメントの判断基準

#### ❌ コメントすべきでない例

- 「〜の可能性がある」という仮説的な問題
- 既存コードでも同様に対応されていない一般論
- 明確な根拠のない「ベストプラクティス」
- 現在のPRの目的・スコープ外の改善提案

#### ✅ コメントすべき例

- 明確なバグや不具合
- API仕様との不一致が確認できる箇所
- 既存の実装パターンとの明確な不一致
- セキュリティリスクやパフォーマンス問題

**判断の原則**:
「このコードが原因で実際に問題が起きる具体的なシナリオを説明できるか?」
説明できない場合は指摘しない。

### レビュー対象外

以下はモデリング層ではなく、他の層でレビューすること：

- **ページコンポーネント**（\*.vue ファイル）→ プロトタイピング層で扱う
- **ルーティング定義**（router 設定）→ プロトタイピング層で扱う
- **UIコンポーネント**（template 部分）→ 表示・スタイリング層で扱う
- **フォーム処理**（バリデーション、送信処理）→ データ処理層で扱う
