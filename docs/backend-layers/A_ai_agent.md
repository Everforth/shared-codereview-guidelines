## AI Agent層（Agentの実装、ツール定義、型定義 等）

### 必須チェック項目：

- **命名による責務の明確性**: 今回追加された名前が既存の類似した名前と責務の違いを判別できるかを確認する。判別できない場合は🔴修正必須として指摘する
- **型定義パターンの遵守**: Tool入力用スキーマと内部保存用の型を適切に分離しているか
- **Transform関数の配置**: AI入力から内部形式への変換ロジックを適切に実装しているか
- **FunctionCallResultの設計**: Agent別の結果型が適切に定義され、result.messageの役割が明確か
- **additionalDataの管理**: ChatMessage.dataに焼くべきデータと焼かないデータが適切に区別されているか
- **RunStepによる監査ログ**: Tool実行の入出力が適切に記録されているか
- **空スキーマの定義ファイル不要**: 中身が空の型定義（`z.object({})`など）は別ファイルに分離せず使用箇所に直接記述する
- **AIツールの戻り値の最小化**: ツール結果は`message`のみ使用されるため、プログラム的に処理するデータ（ID等）以外は返さない
- **検索ツールの寛容な設計**: 重複登録防止などが目的の検索ツールは、呼び出し側が正確に指定しなくても候補を見つけられる寛容な設計にする

---

### 1. 型定義パターン

#### 1.1 Tool入力用スキーマ（Zod）

OpenAI Structured Outputは全フィールドrequiredのため、optional → nullable（`z.union([z.string(), z.null()])`）で表現する。

```typescript
// OpenAI Structured Outputは全フィールドrequired
// optional → nullable (z.union([z.string(), z.null()]))

export const OrderDraftItemRequestSchema = z.object({
  item_num: z.string(),               // required
  quantity: z.number(),               // required
  pack_size: z.union([z.string(), z.null()]),  // optional → nullable
  uom: z.enum(['CS', 'Ea', 'Lbs', '']),
  status: z.enum(['success', 'todo']),
  confidence: z.enum(['high', 'medium', 'low']),
});
```

#### 1.2 内部保存用の型（Tool入力とは別）

AI入力と内部保存で型を分離し、nullの扱いなど変換を明確にする。

```typescript
// AI入力: pack_size: string | null
// 内部保存: pack_size: string (nullは空文字に変換)

export type OrderEntryPayloadItem = Omit<
  z.infer<typeof OrderDraftItemRequestSchema>,
  'pack_size'
> & {
  pack_size: string;  // null → '' に変換
};

export type OrderEntryPayload = {
  items: OrderEntryPayloadItem[];
  isSaved: boolean;  // UI操作で変更されるフラグ（AIは触らない）
};
```

#### 1.3 Transform関数

AI入力から内部保存形式への変換、および外部API用への変換を明示的に関数化する。

```typescript
// AI入力 → 内部保存形式
export function transformToOrderEntryPayload(
  params: SaveOrUpdateOrderDraftParams,
): OrderEntryPayload {
  return {
    items: params.order_info.map((item) => ({
      ...item,
      pack_size: item.pack_size === null ? '' : item.pack_size,
    })),
    isSaved: false,  // AIが作ったものは常にfalse
  };
}

// 内部保存 → 外部API用（不要フィールド削除）
export function transformToSaveOrderRequest(params): ToSaveOrderRequestParams {
  return {
    order_info: params.order_info.map((item) => ({
      item_num: item.item_num,
      quantity: item.quantity,
      uom: item.uom,
      remark: item.remark,
      // original_text, status, help_request_message, confidenceは送らない
    })),
  };
}
```

---

### 2. FunctionCallResult パターン

#### 2.1 Agent別の結果型

基本構造: `status` + `result.message` + Agent固有のデータ

```typescript
// Sales Agent用
export class FunctionCallResult {
  status: 'success' | 'error';
  result: {
    message?: string;
    savedOrderRequestId?: number;      // UI表示用にadditionalDataに焼く
    referencedOrderRequestId?: number; // UI表示用にadditionalDataに焼く
  };
}

// OrderEntryWorkflow用
export class OrderEntryWorkflowFunctionCallResult {
  status: 'success' | 'error';
  result: {
    message?: string;
    outputReport?: OutpurReport;  // UI表示用にadditionalDataに焼く
  };
}

// Reviewer Agent用
export class ReviewerAgentFunctionCallResult {
  status: 'success' | 'error';
  result: {
    message?: string;
    reviewerAgentOutput?: ReviewerAgentOutput;  // 呼び出し元に返す
  };
}
```

#### 2.2 result.message の役割

`result.message`はOpenAIが次のターンで参照する情報であり、UIには直接出ない。

```typescript
// OpenAIに返すもの（function_call_output）
messages.push({
  type: 'function_call_output',
  call_id: callId,
  output: JSON.stringify(result),  // ← result全体をJSON化
});
```

---

### 3. additionalData パターン

#### 3.1 ChatMessage.data の構造

フロントからの入力とバックエンド処理で追加されるデータを型で明確に分離する。

```typescript
// Input（フロントから受け取る）
export type ChatMessageAdditionalDataInput = {
  customerAccountNumber?: number;
  customerAccountName?: string;
  branchOrgId?: number;
  attachments?: UploadedResult[];
  domSnapshot?: DomSnapshotInput;
};

// 保存時（バックエンド処理で追加）
export type ChatMessageAdditionalData = ChatMessageAdditionalDataInput & {
  // SalesAgentの処理結果
  savedOrderRequestId?: number;
  referencedOrderRequestId?: number;
  // OrderEntryWorkflowの処理結果
  outputReport?: OutpurReport;
  // AnalyzeAgentの処理結果
  openaiFileAnnotations?: ResponseAnnotation[];
};
```

#### 3.2 何をadditionalDataに焼くか

| データ                   | 焼く | 理由                            |
| ------------------------ | ---- | ------------------------------- |
| savedOrderRequestId      | OK   | UI表示・次ターンのcontext注入   |
| referencedOrderRequestId | OK   | UI表示・次ターンのcontext注入   |
| outputReport             | OK   | UI表示（サマリーカード）        |
| attachments              | OK   | ファイル参照                    |
| Tool実行の途中結果       | NG   | RunStepに記録                   |
| workingMemory            | NG   | ChatTransaction.workingMemoryに |

#### 3.3 additionalData → context注入

```typescript
async buildContentFromAdditionalData(chatMessage: ChatMessage, userId: number) {
  const additionalData = chatMessage.data;
  if (!additionalData) return chatMessage.text;

  let context = '\n\n';
  return `${chatMessage.text}\n\n${context}`;
}
```

---

### 4. Tool実行 → additionalData焼き込みフロー

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Tool実行                                                      │
├─────────────────────────────────────────────────────────────────┤
│ const result = await this.executeRequestOrder(...);              │
│ // result = { status: 'success',                                │
│ //            result: { message: '...', savedOrderRequestId: 5 }}│
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. OpenAIに返す                                                  │
├─────────────────────────────────────────────────────────────────┤
│ messages.push({                                                  │
│   type: 'function_call_output',                                  │
│   call_id: callId,                                               │
│   output: JSON.stringify(result),                                │
│ });                                                              │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. UI表示用に一時保持                                            │
├─────────────────────────────────────────────────────────────────┤
│ if (result.result.savedOrderRequestId) {                         │
│   savedOrderRequestId = result.result.savedOrderRequestId;       │
│ }                                                                │
└─────────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. 次のresponse.output_textでChatMessage保存時に焼く             │
├─────────────────────────────────────────────────────────────────┤
│ await this.parseMessageAgentService.run(                         │
│   conversation, chatTx, responseText, response.id,               │
│   { savedOrderRequestId, referencedOrderRequestId }  // ← ここ  │
│ );                                                               │
│ savedOrderRequestId = undefined; // リセット                     │
└─────────────────────────────────────────────────────────────────┘
```

**Point**: Tool実行結果は次のassistantメッセージのadditionalDataに焼く

---

### 5. RunStep（監査ログ）

#### 5.1 記録タイミング

Tool実行の前後で記録する。

```typescript
// Tool実行の前後で記録
let runStep = new RunStep(userMessage.chatTransactionId, toolName);
runStep.input = toolArgs;           // ← Tool呼び出し時の引数
runStep = await this.manager.save(runStep);

const result = await this.executeFunctionCall(...);

runStep.output = result;            // ← 実行結果
await this.manager.save(runStep);
```

#### 5.2 記録内容

```typescript
@Entity()
export class RunStep {
  @Column()
  toolName: string;

  @Column({ type: 'jsonb' })
  input: any;   // Tool引数（パース済み or 生文字列）

  @Column({ type: 'jsonb' })
  output: any;  // FunctionCallResult
}
```

**Point**: RunStepはデバッグ・監査用。UIには出さない。

---

### 6. parseAndValidateToolArgs ヘルパー

JSON文字列のパースとZodバリデーションを統一的に行うヘルパー関数。

```typescript
export function parseAndValidateToolArgs<T>(
  toolArgs: unknown,
  schema: z.ZodSchema<T>,
  toolName: string,
): { success: true; data: T } | { success: false; error: string } {
  // Step 1: JSON文字列ならパース
  const parseResult = ParseToolArgsSchema.safeParse(toolArgs);
  if (!parseResult.success) {
    return { success: false, error: `Invalid JSON for ${toolName}...` };
  }

  // Step 2: Zodスキーマでバリデーション
  const validationResult = schema.safeParse(parseResult.data);
  if (!validationResult.success) {
    return { success: false, error: `Invalid parameters for ${toolName}...` };
  }

  return { success: true, data: validationResult.data };
}
```

**使用例:**

```typescript
case 'save_order_draft':
  const result = parseAndValidateToolArgs(
    toolArgs,
    SaveOrUpdateOrderDraftParamsSchema,
    'save order draft',
  );
  if (!result.success) {
    return { status: 'error', result: { message: result.error } };
  }
  const params = result.data;  // 型安全
  // ...
```

---

### 7. データの流れまとめ

```
┌──────────────────────────────────────────────────────────────────────┐
│ Tool入力                                                              │
│ (Zodスキーマ、nullable許容)                                           │
└───────────────────────────────────┬──────────────────────────────────┘
                                    ↓ parseAndValidateToolArgs
┌───────────────────────────────────┴──────────────────────────────────┐
│ 内部処理                                                              │
│ (Transform関数でnull→空文字、不要フィールド削除)                       │
└───────────────────────────────────┬──────────────────────────────────┘
                                    ↓
        ┌───────────────────────────┼───────────────────────────┐
        ↓                           ↓                           ↓
┌───────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ RunStep       │         │ Entity更新       │         │ FunctionCall    │
│ (監査ログ)    │         │ (OrderRequest等) │         │ Result          │
└───────────────┘         └─────────────────┘         └────────┬────────┘
                                                               ↓
                                                  ┌────────────┴────────────┐
                                                  ↓                         ↓
                                        ┌─────────────────┐       ┌─────────────────┐
                                        │ OpenAIに返す    │       │ UI表示用に保持   │
                                        │ (message)       │       │ (xxxId, report) │
                                        └─────────────────┘       └────────┬────────┘
                                                                           ↓
                                                              ┌────────────────────────┐
                                                              │ ChatMessage.data       │
                                                              │ (additionalData)       │
                                                              └────────────────────────┘
```

---

### この層で扱わないこと：

- Entity定義（DB層の責務）
- APIエンドポイント定義（Controller層の責務）
- ビジネスロジック（Service層の責務）
