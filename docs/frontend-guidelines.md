# フロントエンド レビューガイドライン

## Vue.js 特有の指摘事項

### Vue SFC設計思想
- **適度な肥大化を許容**: ページコンポーネントはある程度肥大化してよく、単一責任の原則に従いすぎてファイルが増えるのを避ける
- **分離は最小限**: レイアウトごとの分離程度に留める
- **表示目的のみの分割禁止**: 単純な表示目的だけでのコンポーネント分割は避ける

### 結合度と凝集度
- **結合度（Coupling）減らすべき**: 異なるコンポーネント間の依存関係、コンポーネントと外部システムの依存
- **凝集度（Cohesion）高めるべき**: 同一コンポーネント内の要素の一体性、関連する機能の近接配置
- **原則**: 「一緒に変更されるものは、近くに配置すべき」

### v-model の適切な使用
```typescript
// ❌ Bad - v-modelでbindしてるものを、その仕組みの外で変更
function onSwitchIncludeOutdated(v: string | number | boolean) {
  getProductsQuery.value = { ...getProductsQuery.value, includeOutdated: v === true }
}

// ✅ Good - v-bindとrefの機能をそのまま使用
```

### 不要な計算処理の削除
- 独自のpagination計算などは他のページの実装を参考にする
- 既存実装パターンに従い、車輪の再発明を避ける

## TypeScript 型定義

### 既存型定義の再利用
```typescript
// ❌ Bad - 型を再定義
export interface EvalLog {
  adminUser: {
    id: number
    email: string
    name: string
  }
}

// ✅ Good - 既存型定義をimport
import { AdminUser } from '@/types/adminUser.type'
export interface EvalLog {
  adminUser: AdminUser
}
```

### 参考となる型定義ファイル
- `src/types/adminUser.type.ts`
- `src/types/paginationStats.type.ts`

## Pinia Store 実装

### 既存パターンに従う
```typescript
// ❌ Bad - 基本的すぎるstore
export const useEvalLogStore = defineStore('evalLogStore', {
  state: () => ({
    evalLogs: []
  })
})

// ✅ Good - productStore.tsなどをベースにした実装
```

### 参考実装
- `src/stores/productStore.ts`

## UI/UX 改善

### エラーメッセージの改善
| ❌ Bad | ✅ Good |
|--------|---------|
| '現在サービスを一時的に停止しています。お時間をおいて再度お試しください。' | 'AIサービスに障害が発生中です。お時間をおいて再度お試しください。' |
| '現在サービスの一部が繋がりにくい状況です。繋がらない場合はお時間をおいて再度お試しください。' | 'AIサービスが繋がりにくい状況のようです。繋がらない場合はお時間をおいて再度お試しください。' |

### 不要なUI表示の除去
```typescript
// ❌ Bad - handleRetryボタンが押せる場合にエラーメッセージ表示
if (canRetry) {
  showErrorMessage(error)  // 不要
}

// ✅ Good - console/Sentryへの出力
console.error(error)
```

## 命名規約

### 意図を表す命名
| ❌ Bad | ✅ Good | 理由 |
|--------|---------|------|
| `five` | `recent` | 5未満だったときや、複数のconversationにまたがないと5件取れないときについて曖昧になる |
| `is〜` | `can〜` | boolean変数の意味に応じて適切に |

### 暗黙的な処理の回避
```typescript
// ❌ Bad - currentConversation == undefinedというstateを使った暗黙的な処理
if (currentConversation == undefined) {
  // 何か特殊な処理
}

// ✅ Good - 明示的な状態管理
```

## コメント・ドキュメント

### 情報量のないコメントは削除
```typescript
// ❌ Bad - 情報量がないコメント
state.users_stats = res.data.meta // APIレスポンス構造に合わせる

// ✅ Good - コメント不要、またはコードで自明
state.users_stats = res.data.meta
```

**ルール**:
- inlineコメントは、コードに対する説明として意味のあるものにする
- 変更差分の説明を残すのはやめる
- そういう補足をしたいときはPRに説明やレビューコメントで書く

## プロジェクト構造

### 技術スタック
- Vue.js 3 + TypeScript + Composition API
- Pinia (状態管理)
- Vue Router
- Element Plus (UI ライブラリ)
- Vite (ビルドツール)

### ディレクトリ構成への配慮
- `src/views/`: ページコンポーネント  
- `src/components/`: 再利用可能なコンポーネント
- `src/stores/`: Pinia状態管理
- `src/types/`: TypeScript型定義
- Props/Emits の型定義を明確化
- 未使用コンポーネントは削除

## レビューの重点項目

### 必須チェック項目
- [ ] 情報量のないコメントは削除されているか
- [ ] 命名は明確で意図が伝わるか
- [ ] v-modelの扱いは適切か（仕組みの外で変更していないか）
- [ ] 既存の型定義を再利用しているか
- [ ] Store実装は既存パターンに従っているか
- [ ] エラーメッセージはユーザーに分かりやすいか
- [ ] 暗黙的な処理を避けているか

### 推奨チェック項目
- [ ] 不要な計算処理は削除されているか（既存実装を参考に）
- [ ] 型定義は十分に整備されているか
- [ ] UI/UXは適切か（不要なエラー表示等）
- [ ] スタイルはScopedCSSで実装されているか
- [ ] 動作例（スクリーンショット等）が提示されているか