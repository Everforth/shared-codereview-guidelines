## Enum定義・運用ガイドライン

### 1. 基本方針

- **DB enumは削除しない**: 過去レコードの保持を優先する
- **仕様から外れた値は「deprecated」として扱う**: コード上で明示的に分離する
- **コードの可読性・型安全性を守る**: 現役仕様が一目で分かる状態を保つ
- **DB表現方式は2方式から選ぶ**: PostgreSQL ENUM 型方式 / text + CHECK 制約方式

---

### 2. 二層定義パターン

#### 目的

- コードを見れば「現役仕様」が一目で分かる状態を保つ
- DBに残るlegacy値を仕様から隔離する

#### ルール

- **全集合（legacy含む）** と **現役仕様** を分けて定義する
- アプリの業務ロジック・DTOは **現役仕様のみ** を使う

#### 実装例

```typescript
// ============================================
// 全集合（legacy含む）
// ============================================
export const ConversationAgentAll = {
  salesAgent: 'salesAgent',
  orderEntryWorkflow: 'orderEntryWorkflow',
  analyzeAgent: 'analyzeAgent',
  marketAgent: 'marketAgent',
  // deprecated
  legacyAgent: 'legacyAgent',
} as const;

export type ConversationAgentAll =
  typeof ConversationAgentAll[keyof typeof ConversationAgentAll];

// ============================================
// 現役仕様（新規に使ってよい集合）
// ============================================
export const ConversationAgent = {
  salesAgent: ConversationAgentAll.salesAgent,
  orderEntryWorkflow: ConversationAgentAll.orderEntryWorkflow,
  analyzeAgent: ConversationAgentAll.analyzeAgent,
  marketAgent: ConversationAgentAll.marketAgent,
} as const;

export type ConversationAgent =
  typeof ConversationAgent[keyof typeof ConversationAgent];
```

#### 使い分け

| 用途                        | 使用する型                      |
| --------------------------- | ------------------------------- |
| Entity定義（DBカラムの型）  | `ConversationAgentAll`          |
| DTO・バリデーション         | `ConversationAgent`（現役仕様） |
| Service層のビジネスロジック | `ConversationAgent`（現役仕様） |
| DBからの読み取り結果の型    | `ConversationAgentAll`          |

---

### 3. ENUM 型方式: DB / Migration ルール

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
    enum: Object.values(ConversationAgentAll).sort(), // 並び順を固定
    default: ConversationAgentAll.salesAgent
  })
  agent: ConversationAgentAll;
}
```

#### 禁止事項

- `synchronize: true` でのenum自動変更
- TypeORMが生成するmigrationでのenum変更（手書きで上書きすること）
- DB enumからの値削除（過去データが参照できなくなる）

---

### 4. text + CHECK 制約方式: DB / Migration ルール

カラムは text 型、許可値は `@Check` で表現、TS 側は enum で型付けする方式。ENUM 型方式の「`ALTER TYPE ... ADD VALUE` した値が同一トランザクション内で使えない」制約を回避したい場合に採る。

- **CHECK 制約は固定名 + ハードコード許可値で書く**
  - 制約名は文字列リテラルで指定する
  - 許可値は文字列リテラルでベタ書きする（`Object.values(ENUM)` / `.map(...).join(...)` / テンプレートリテラル展開での動的生成は禁止）
  - 理由: TypeORM の `migration:generate` は CHECK 制約**名**で差分判定する。名前が同じまま許可値だけ変わっても差分が出ず、migration 生成漏れにつながる
- **Entity のカラム型に使われている enum の値が変更された PR では、対応する手書き migration が PR に含まれているか確認する**
  - 対象は Entity の `@Column` 型注釈に使われている enum のみ。DTO・フロント表示用など DB に流れない enum は対象外
  - migration が見当たらない場合は、別 PR で出す予定か・不要なのかを確認する（`migration:generate` は許可値変更を検知しないため、自動生成に任せるのは不可）

#### 実装例

```typescript
@Entity()
@Check('chk_orders_status', "status IN ('draft', 'submitted', 'confirmed', 'cancelled')")
export class Order {
  @Column({ type: 'text' })
  status: OrderStatusAll;
}
```

#### 手書きMigrationの書き方（許可値を追加する場合）

```sql
ALTER TABLE "orders" DROP CONSTRAINT "chk_orders_status";
ALTER TABLE "orders" ADD CONSTRAINT "chk_orders_status"
  CHECK (status IN ('draft', 'submitted', 'confirmed', 'cancelled', 'shipped'));
```
