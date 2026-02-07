## DB層（Entity定義, 型定義, スキーマ定義 等）

### 必須チェック項目：

- データモデル設計: 何をしたいからどういうデータモデルであるべきかの意図が明確で適切か
- 命名規則: テーブル名やカラム名が業務の意味を正確に表現し、一貫性があるか
- 制約設計: 状態を極力持たず、DB制約でデータの整合性を保証することでService層のif文を減らしているか
- nullable設計:
  - 基本NOT NULLとし、`nullable: false`の明示はしない
  - 値なしに意味がある場合のみnullableにし、optional markもつける
  - 区別不要なら`default: ''`を使用する
- リレーションのnullable設計:
  - 両側で異なるnullable設定は正当であり、整合性の問題として指摘しないこと
  - 親エンティティ側では子が存在しない場合があればnullableとする
  - 子エンティティ側では親への参照は通常必須となる
  - 外部キーカラムがnullable: falseで、リレーション側がnullable: trueでも問題ない
- 型設計: 既存型定義を再利用しているか
- DB操作: TypeORMクエリが最適化され、N+1問題を避けているか
- Enum定義: Enumを Entity内に書かず、types/ディレクトリ内ファイルに分離する（ @shared-codereview-guidelines/docs/backend-layers/B_Enum定義.md を参照）
- デフォルト値: カラムに適切なdefault値を設定し、マジックナンバーではなく定義済み定数を使用する
- 外部キー定義: リレーションを定義する場合、対応する外部キーカラムも明示的に定義する
- Entityのコンストラクタ:
  - 🔴修正必須: 外部キー（userId等）をコンストラクタで受け取っていない場合（外部キーはdefault設定不可のため）
  - 🟨確認: 外部キー以外の必須フィールドにdefaultがない場合、default設定漏れかコンストラクタ追加かを質問する
- 情報の重複回避: 他のカラムやリレーションから導出可能な情報は、別カラムとして持たない
- リレーションの優先: 会社名などマスタデータを参照すべき値は、文字列カラムではなくリレーションで定義する
- その他のTypeORMの慣習尊重: デフォルト値の明示やコンストラクタでの全プロパティ初期化など、他の項目以外に対してTypeORMの一般的なパターンに反する指摘をしない

### パフォーマンス考慮点：

- バッチ処理での一括操作
- 不要なDB呼び出しの削減

### 設計考慮点：

- Migrationの適切な統合
- 既存データがあるテーブルにNOT NULLカラムを追加する場合、一時的にdefault値を設定し削除用のTODOを残す

### 正当な設計パターン：

- リレーションの両側で異なるnullable設定
- nullable: falseの省略（TypeORMのデフォルト動作）
- 代替設計パターンの提案（シングルトン化、別モジュールへの統合など）

### この層で扱わないこと：

- DTOファイル（Controller層の責務）
- CRUD処理の実装（Service層の責務）
- ビジネスロジック（Service層の責務）
- APIエンドポイントの定義（Controller層の責務）

### PostgreSQL特有の注意点：

- Decimal/Numeric型: JavaScriptのnumber精度を超えるため、ORMではStringとして返却される
- BigInt/BigSerial型: `Number.MAX_SAFE_INTEGER`を超える値で精度損失。ORMではStringまたはBigInt型でマッピング
- Array型: TypeORMでは`@Column('integer', { array: true })`で定義。`@Column('array')`はエラー
- Boolean型: `WHERE column = NULL`ではなく`WHERE column IS NULL`を使用
