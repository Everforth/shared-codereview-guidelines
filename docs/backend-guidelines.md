# バックエンド レビューガイドライン

## 全体的な方針

- コードの可読性と保守性を重視する
- 既存の設計パターンやベストプラクティスに従う
- パフォーマンスとセキュリティを考慮する
- 適切なエラーハンドリングとバリデーションを実装ができているかを確認する
- 妥当性のあるコードを厳格に かつ 無駄を少なく綺麗に改善できるよう指摘する

## NestJS 設計パターン

### Controller/Service 責務分離
```typescript
// ❌ Bad - controllerで複雑な処理
@Controller('push-notification')
export class PushNotificationController {
  @Post('test')
  async sendTest(@Body() dto: SendTestDto) {
    // ここで複雑なvalidationや処理はやり過ぎ
    if (dto.userRole !== 'admin') {
      throw new ForbiddenException();
    }
    // serviceの仕事
  }
}

// ✅ Good - controllerは接続とDTOベースvalidation程度
@Controller('push-notification')
export class PushNotificationController {
  @Post('test')
  async sendTest(@Body() dto: SendTestDto) {
    return this.pushNotificationService.sendTest(dto);
  }
}
```

### DTO設計

#### PartialType活用
```typescript
// ❌ Bad - ほぼoptionalなのに個別定義
export class UpdateGameDto {
  title?: string;
  description?: string;
  imageUrl?: string;
  // ... 他のoptionalフィールド
}

// ✅ Good - PartialTypeで定義
export class UpdateGameDto extends PartialType(CreateGameDto) {}
```

#### 既存型定義の参照
```typescript
// ❌ Bad - 型を再定義
interface UserData {
  id: number;
  email: string;
  name: string;
}

// ✅ Good - 既存のuser-role.typeを参照
import { UserRole } from '@/users/types/user-role.type';
```

## TypeORM 実装

### Entity設計
```typescript
// ❌ Bad - 不適切なPrimaryGeneratedColumn
@Entity()
export class Game {
  @PrimaryGeneratedColumn()
  id: string; // uuidにしたいなら
}

// ✅ Good - 適切なuuid生成
@Entity()
export class Game {
  @PrimaryGeneratedColumn("uuid")
  id: string;
}
```

### Query最適化
```typescript
// ❌ Bad - 複数SQL発行
const user = await this.userRepository.findOne(id);
const userDetails = await this.userRepository.findOne({
  where: { id },
  relations: ['profile']
});

// ✅ Good - QueryBuilderで1回
const user = await this.userRepository
  .createQueryBuilder('user')
  .leftJoinAndSelect('user.profile', 'profile')
  .where('user.id = :id', { id })
  .getOne();
```

## エラーハンドリング

### 適切なHTTPステータス
```typescript
// ❌ Bad - 何もしなければ500になるのでcatchして500にする意味なし
try {
  await this.someService.process();
} catch (error) {
  throw new InternalServerErrorException();
}

// ✅ Good - 適切なステータスに変換するかそのまま
try {
  await this.someService.process();
} catch (error) {
  if (error.code === 'NOT_FOUND') {
    throw new NotFoundException();
  }
  throw error; // 500のままで良い場合
}
```

### updateとdeleteでの404処理
```typescript
// ❌ Bad - 普通ではない404扱い（理由をコメントで明記）
try {
  await this.repository.update(id, data);
} catch (error) {
  throw new NotFoundException(); // なぜ404にするかコメント必要
}

// ✅ Good - 理由が明確、または適切なエラー処理
const result = await this.repository.update(id, data);
if (result.affected === 0) {
  throw new NotFoundException('リソースが見つかりません');
}
```

## バリデーション・型安全性

### DTOでの適切なバリデーション
```typescript
// ❌ Bad - 必要なバリデーションが不足
export class UpdateGameDto {
  displayPriority: number;
}

// ✅ Good - 適切なバリデーション
export class UpdateGameDto {
  @IsInt()
  displayPriority: number;
}
```

### 型推論エラーの適切な対処
```typescript
// ❌ Bad - asで型エラーを握りつぶす
const productRoot = data as ProductRoot;

// ✅ Good - 既存のフィールドを使用
const productRoot = await this.repository.findOne({
  where: { gpRootId: data.gpRootId }
});
```

## テスト設計

### E2Eテストでの権限テスト
```typescript
// ❌ Bad - 権限のテストができない
it('should get data', async () => {
  await request(app.getHttpServer())
    .get('/endpoint')
    .expect(200);
});

// ✅ Good - products.e2e-specを参考にした権限テスト
describe('Authorization', () => {
  it('should deny access without token', async () => {
    await request(app.getHttpServer())
      .get('/endpoint')
      .expect(401);
  });
  
  it('should allow access with valid token', async () => {
    await request(app.getHttpServer())
      .get('/endpoint')
      .set('Authorization', validToken)
      .expect(200);
  });
});
```

### テストデータの管理
```typescript
// ❌ Bad - API経由でテストデータ作成
beforeEach(async () => {
  await request(app.getHttpServer())
    .post('/test-data')
    .send(testData);
});

// ✅ Good - seedで作成、または直接dataSource経由
beforeEach(async () => {
  await dataSource.getRepository(TestEntity).save(testData);
});
```

## パフォーマンス考慮

### バッチ処理の最適化
```typescript
// ❌ Bad - 1つずつ順番に処理
for (const item of items) {
  await this.repository.save(item);
}

// ✅ Good - 一括処理
const entities = items.map(item => this.repository.create(item));
await this.repository.save(entities);
```

### キャッシュ設計
```typescript
// ❌ Bad - キャッシュ時間が短すぎる可能性
@CacheTTL(300) // 5分
async getProducts() {
  return this.productService.findAll();
}

// ✅ Good - 適切なキャッシュ期間の検討
@CacheTTL(1800) // 30分（商品情報は頻繁に変わらない）
async getProducts() {
  return this.productService.findAll();
}
```

## API設計

### エンドポイント命名
```typescript
// ❌ Bad - IDと混同しやすい
@Get('/products/colored-contact-lens/bundle-discount-candidates/:id')
getBundleDiscountCandidates(@Param('id') id: string) {
  // idがカラコン商品のidかバンドル割引のidか不明
}

// ✅ Good - queryパラメータで明確化
@Get('/products/colored-contact-lens/bundle-discount-candidates')
getBundleDiscountCandidates(@Query('bundleDiscountId') bundleDiscountId?: string) {
  // 意図が明確
}
```

### セキュリティ設定
```typescript
// ❌ Bad - ガードの重複設定
@SkipJwtAuth()
@UseGuards(JwtAuthGuard) // 矛盾している
@Controller('api')
export class ApiController {}

// ✅ Good - 適切なガード設定
@SkipJwtAuth()
@UseGuards(ApiKeyGuard)
@Controller('inter-server')
export class InterServerController {}
```

## Migration管理

### Migration統合
- 複数の小さなmigrationは1つにまとめる
- 関連する変更は同じmigrationで実行
- データ移行も含めて一貫性を保つ

## コメント・ドキュメント

### 理由の明記
```typescript
// ❌ Bad - 理由が不明な特殊設定
@Column({ nullable: true })
isActive: boolean;

// ✅ Good - 理由をコメントで説明
@Column({ 
  nullable: true // GPからの同期でnullの場合があるため
})
isActive: boolean;
```

### 命名の改善
```typescript
// ❌ Bad - users moduleと名前衝突
export class UpdateUsualPowersDto {}

// ✅ Good - モジュール固有の命名
export class UpdateInterServerUsualPowersDto {}
```

## レビューの重点項目

### 必須チェック項目
- [ ] Controller/Serviceの責務分離は適切か
- [ ] DTOの設計は適切か（PartialType活用、既存型参照）
- [ ] TypeORMの使用方法は効率的か
- [ ] エラーハンドリングは適切なHTTPステータスを返すか
- [ ] バリデーションは十分か
- [ ] セキュリティ設定は適切か
- [ ] テストは権限チェックを含んでいるか

### 推奨チェック項目
- [ ] パフォーマンスを考慮した実装か
- [ ] API設計は RESTful で一貫しているか
- [ ] Migrationは適切に統合されているか
- [ ] コメントで理由や特殊事情が説明されているか
- [ ] 命名は他のモジュールと衝突していないか
