## モデリング層（型定義, ストア定義 等）

### 必須チェック項目：

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

### 設計・命名規則：

- 型定義ファイル名は `{entity}.type.ts` 形式
- ストア名は `use{Entity}Store` 形式
- メソッド名は `get{Entity}`, `create{Entity}`, `update{Entity}`, `delete{Entity}` 形式

### レビュー対象外：

以下はモデリング層ではなく、他の層でレビューすること：

- **ページコンポーネント**（\*.vue ファイル）→ プロトタイピング層で扱う
- **ルーティング定義**（router 設定）→ プロトタイピング層で扱う
- **UIコンポーネント**（template 部分）→ 表示・スタイリング層で扱う
- **フォーム処理**（バリデーション、送信処理）→ データ処理層で扱う
