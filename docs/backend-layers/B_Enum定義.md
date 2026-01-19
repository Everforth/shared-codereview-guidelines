## Enum定義・運用ガイドライン

### 1. 基本方針

- **DB enumは削除しない**: 過去レコードの保持を優先する
- **仕様から外れた値は「deprecated」として扱う**: コード上で明示的に分離する
- **コードの可読性・型安全性を守る**: 現役仕様が一目で分かる状態を保つ

---

### 2. 二層定義パターン

#### 目的

- コードを見れば「現役仕様」が一目で分かる状態を保つ
- DBに残るlegacy値を仕様から隔離する

#### ルール

- **DB全集合（legacy含む）** と **現役仕様** を分けて定義する
- アプリの業務ロジック・DTOは **現役仕様のみ** を使う

#### 実装例

```typescript
// ============================================
// 全集合（legacy含む）
// ============================================
export const ConversationAgentDb = {
  salesAgent: 'salesAgent',
  orderEntryWorkflow: 'orderEntryWorkflow',
  analyzeAgent: 'analyzeAgent',
  marketAgent: 'marketAgent',
  // deprecated
  legacyAgent: 'legacyAgent',
} as const;

export type ConversationAgentDb =
  typeof ConversationAgentDb[keyof typeof ConversationAgentDb];

// ============================================
// 現役仕様（新規に使ってよい集合）
// ============================================
export const ConversationAgent = {
  salesAgent: ConversationAgentDb.salesAgent,
  orderEntryWorkflow: ConversationAgentDb.orderEntryWorkflow,
  analyzeAgent: ConversationAgentDb.analyzeAgent,
  marketAgent: ConversationAgentDb.marketAgent,
} as const;

export type ConversationAgent =
  typeof ConversationAgent[keyof typeof ConversationAgent];
```

#### 使い分け

| 用途                        | 使用する型                      |
| --------------------------- | ------------------------------- |
| Entity定義（DBカラムの型）  | `ConversationAgentDb`           |
| DTO・バリデーション         | `ConversationAgent`（現役仕様） |
| Service層のビジネスロジック | `ConversationAgent`（現役仕様） |
| DBからの読み取り結果の型    | `ConversationAgentDb`           |

---

### 3. DB / Migration ルール

#### 基本原則

- **enumの追加・リネームは手書きmigration**で行う
- **TypeORMの自動migrationでenumを変更しない**
- **enumNameは必ず固定**する（Entity側で明示的に指定）
- **deprecated値はDB enumに残したまま運用**する

#### 手書きMigrationの書き方

##### 新しいenum値を追加する場合

```sql
-- 新しいenum値を追加
ALTER TYPE conversation_agent
ADD VALUE IF NOT EXISTS 'marketAgentV2';
```

##### enum値をリネームする場合

```sql
-- enum値をリネーム
ALTER TYPE conversation_agent
RENAME VALUE 'analyzeAgent' TO 'analysisAgent';
```

##### 新しいenum型を作成する場合

```sql
-- 新しいenum型を作成
CREATE TYPE order_status AS ENUM ('draft', 'submitted', 'confirmed', 'cancelled');
```

#### TypeORM Entity側の設定

```typescript
@Entity()
export class Conversation {
  @Column({
    type: 'enum',
    enum: ConversationAgentDb,
    enumName: 'conversation_agent',  // ← 必ず固定名を指定
  })
  agent: ConversationAgentDb;
}
```

#### 禁止事項

- `synchronize: true` でのenum自動変更
- TypeORMが生成するmigrationでのenum変更（手書きで上書きすること）
- DB enumからの値削除（過去データが参照できなくなる）
