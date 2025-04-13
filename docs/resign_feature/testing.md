# テスト仕様

## 1. モデルテスト
```ruby
# spec/models/game_spec.rb
RSpec.describe Game, type: :model do
  # ... (元のテスト仕様と同じ)
end
```

## 2. APIテスト
```ruby
# spec/requests/api/v1/games_spec.rb
RSpec.describe 'Games API' do
  # ... (元のテスト仕様と同じ)
end
```

## 3. フロントエンドテスト
```typescript
// frontend/tests/components/ResignButton.spec.ts
describe('ResignButton', () => {
  // コンポーネントのテスト
});
``` 