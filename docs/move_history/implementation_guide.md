# 将棋GUI 手の履歴機能 - 実装ガイド

## 概要

本ドキュメントは将棋GUIの手の履歴機能を実装するための手順と注意点をまとめたものです。バックエンド（Ruby on Rails）とフロントエンド（Vue.js）の両方の実装手順を記載しています。バックエンドはDockerコンテナ上で動作しています。

## 実装手順

### 1. データベース構築

#### マイグレーションファイルの作成

```bash
# Railsコンテナ内でマイグレーションファイルを生成
docker-compose exec backend rails generate migration CreateBoardHistories
```

以下のようにマイグレーションファイルを編集します：

```ruby
class CreateBoardHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :board_histories do |t|
      t.references :game, null: false, foreign_key: true
      t.string :sfen, null: false
      t.integer :move_number, null: false
      t.string :branch, default: 'main'
      t.timestamps
    end
    
    add_index :board_histories, [:game_id, :move_number, :branch], unique: true
  end
end
```

マイグレーションを実行します：

```bash
# Railsコンテナ内でマイグレーションを実行
docker-compose exec backend rails db:migrate
```

#### モデルの作成

`app/models/board_history.rb`ファイルを作成します：

```ruby
class BoardHistory < ApplicationRecord
  belongs_to :game

  validates :sfen, presence: true
  validates :move_number, presence: true, uniqueness: { scope: [:game_id, :branch] }
  validates :branch, presence: true

  scope :ordered, -> { order(move_number: :asc) }
  scope :main_branch, -> { where(branch: 'main') }

  # 前の局面を取得
  def previous_board_history
    return nil if move_number <= 0
    game.board_histories.where(branch: branch)
                      .find_by(move_number: move_number - 1)
  end
  
  # 次の局面を取得
  def next_board_history
    game.board_histories.where(branch: branch)
                      .where('move_number > ?', move_number)
                      .order(move_number: :asc).first
  end

  # 最初の局面を取得
  def first_board_history
    game.board_histories.where(branch: branch).ordered.first
  end

  # 最後の局面を取得
  def last_board_history
    game.board_histories.where(branch: branch).ordered.last
  end

  # 前の局面との差分から手の情報を取得
  def get_move_info
    prev_history = previous_board_history
    return nil unless prev_history

    current_parsed = Parser::SfenParser.parse(sfen)
    previous_parsed = Parser::SfenParser.parse(prev_history.sfen)
    
    # 局面の差分から手の情報を計算
    calculate_move_info(current_parsed, previous_parsed)
  end

  # 棋譜形式で手を表示
  def to_kifu_notation
    return "開始局面" if move_number == 0

    # 前の局面が見つからない場合
    prev_history = previous_board_history
    return "#{move_number}手目" unless prev_history

    # SFENから局面情報を計算（最小限の情報のみ）
    current_parsed = Parser::SfenParser.parse(sfen)
    previous_parsed = Parser::SfenParser.parse(prev_history.sfen)
    
    # 手番
    player_type = previous_parsed[:side]
    player_symbol = player_type == 'b' ? '▲' : '△'
    
    # 移動先と駒種（基本的な情報のみ）
    # ... 簡略化した処理 ...
    
    # 棋譜表記を組み立て
    "#{player_symbol}#{to_notation}#{piece_name}#{special_notation}"
  end

  private

  def calculate_move_info(current, previous)
    # 局面の差分から手の情報を計算するロジック
    # 例：駒の位置の変化から移動元と移動先を特定
    # 例：駒の種類の変化から成り/不成りを判定
  end
end
```

#### 既存モデルの更新

`app/models/game.rb`を更新します：

```ruby
class Game < ApplicationRecord
  has_one :board, dependent: :destroy
  has_many :board_histories, dependent: :destroy
  
  # 既存のコード
end
```

### 2. APIコントローラの実装

#### BoardHistoriesコントローラの作成

`app/controllers/api/v1/board_histories_controller.rb`ファイルを作成します：

```ruby
module Api
  module V1
    class BoardHistoriesController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      
      # 局面履歴の取得
      def index
        @game = Game.find(params[:game_id])
        branch = params[:branch] || 'main'
        
        @histories = @game.board_histories
                         .where(branch: branch)
                         .ordered
        
        render json: @histories.map { |history|
          history.as_json.merge({
            notation: history.to_kifu_notation
          })
        }
      end
      
      # 分岐リストの取得
      def branches
        @game = Game.find(params[:game_id])
        branches = @game.board_histories.pluck(:branch).uniq
        
        render json: { branches: branches }
      end
      
      # 指定した手数の局面に移動
      def navigate_to
        @game = Game.find(params[:game_id])
        branch = params[:branch] || 'main'
        move_number = params[:move_number].to_i
        
        @history = @game.board_histories
                      .where(branch: branch)
                      .find_by(move_number: move_number)
        
        if @history.nil?
          return render json: {
            error: "Move number not found in branch",
            status: 404
          }, status: :not_found
        end
        
        # 現在のボードを更新
        @board = @game.board
        @board.update(sfen: @history.sfen)
        
        render json: {
          game_id: @game.id,
          board_id: @board.id,
          move_number: @history.move_number,
          sfen: @history.sfen
        }
      end
      
      # 分岐切り替え
      def switch_branch
        @game = Game.find(params[:game_id])
        branch_name = params[:branch_name]
        
        # 分岐が存在するか確認
        unless @game.board_histories.where(branch: branch_name).exists?
          return render json: {
            error: "Branch not found",
            status: 404
          }, status: :not_found
        end
        
        # 分岐内の最新局面を取得
        @latest_history = @game.board_histories
                             .where(branch: branch_name)
                             .ordered
                             .last
        
        # 現在のボードを更新
        @board = @game.board
        @board.update(sfen: @latest_history.sfen)
        
        render json: {
          game_id: @game.id,
          branch: branch_name,
          current_move_number: @latest_history.move_number
        }
      end
      
      private
      
      def record_not_found
        render json: {
          error: "Game not found",
          status: 404
        }, status: :not_found
      end
    end
  end
end
```

#### Movesコントローラの更新

既存の`app/controllers/api/v1/moves_controller.rb`を更新します：

```ruby
class Api::V1::MovesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def move
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])
    
    # 分岐情報の取得
    current_move_number = params[:move_number].to_i
    branch = params[:branch] || 'main'
    
    parsed_data = Parser::SfenParser.parse(@board.sfen)
    move_info = Board.parse_move(params[:move])

    # 合法手でない場合はDBに保存しない
    return unless Validator.legal?(parsed_data, move_info, @game)

    # 既存のコード: 次の局面を作成
    next_board = Move.process_move(@game, @board, parsed_data, move_info)
    
    # 分岐処理: 同じ手数で異なる手を指した場合は新しい分岐を作成
    if current_move_number > 0 && @game.board_histories.exists?(move_number: current_move_number)
      next_move_number = current_move_number + 1
      
      # 既存の分岐と手数が同じ場合、新しい分岐名を生成
      if @game.board_histories.exists?(move_number: next_move_number, branch: branch)
        # 既存の分岐をベースに新しい分岐名を生成
        existing_branches = @game.board_histories.where('branch LIKE ?', "#{branch}_%").pluck(:branch)
        max_branch_number = existing_branches.map { |b| b.split('_').last.to_i }.max || 0
        branch = "#{branch}_#{max_branch_number + 1}"
      end
    else
      # 通常の手順（分岐なし）
      next_move_number = parsed_data[:move_number] + 1
    end
    
    # 局面の履歴を保存
    @history = @game.board_histories.create!(
      sfen: next_board.sfen,
      move_number: next_move_number,
      branch: branch
    )
    
    # レスポンスに履歴情報を追加
    render_success(next_board, @game, @history)
  end

  private

  def render_success(next_board, game, history)
    # 既存のコード
    next_board_array = Parser::SfenParser.parse(next_board.sfen)[:board_array]
    next_board_hands = Parser::SfenParser.parse(next_board.sfen)[:hand]
    next_side = Parser::SfenParser.parse(next_board.sfen)[:side]

    render json: {
      status: true,
      is_checkmate: Validator.is_checkmate?(next_board_array, next_board_hands, next_side),
      is_repetition: Validator.repetition?(next_board.sfen, game),
      is_repetition_check: Validator.repetition_check?(next_board_array, next_side, game),
      board_id: next_board.id,
      sfen: next_board.sfen,
      # 追加の情報
      move_number: history.move_number,
      branch: history.branch
    }, status: :ok
  end

  # 既存のエラーハンドリングメソッド
end
```

#### ルーティングの追加

`config/routes.rb`ファイルに新しいルーティングを追加します：

```ruby
Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  
  namespace :api do 
    namespace :v1 do
      # 既存のルート
      
      # 履歴関連のルート
      get '/games/:game_id/board_histories', to: 'board_histories#index'
      get '/games/:game_id/board_histories/branches', to: 'board_histories#branches'
      post '/games/:game_id/navigate_to/:move_number', to: 'board_histories#navigate_to'
      post '/games/:game_id/switch_branch/:branch_name', to: 'board_histories#switch_branch'
    end
  end
end
```

### 3. テスト仕様の作成

#### Rswagテスト仕様

`spec/integration/api/v1/board_histories_spec.rb`ファイルを作成します：

```ruby
require 'swagger_helper'

RSpec.describe 'API::V1::BoardHistories', type: :request do
  path '/api/v1/games/{game_id}/board_histories' do
    get '局面履歴の取得' do
      tags 'BoardHistories'
      produces 'application/json'
      
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :branch, in: :query, type: :string, required: false, description: '分岐名（デフォルト: main）'
      
      response '200', '履歴取得成功' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              game_id: { type: :integer },
              sfen: { type: :string },
              move_number: { type: :integer },
              branch: { type: :string },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' },
              notation: { type: :string, nullable: true }
            }
          }
        
        let(:game_id) { Game.create(status: 'active').id }
        run_test!
      end
      
      response '404', 'ゲームが見つからない' do
        schema type: :object,
          properties: {
            error: { type: :string },
            status: { type: :integer }
          }
        
        let(:game_id) { 'invalid' }
        run_test!
      end
    end
  end
  
  # 他のAPIエンドポイントも同様に定義
end
```

#### モデルのテスト

`spec/models/board_history_spec.rb`ファイルを作成します：

```ruby
require 'rails_helper'

RSpec.describe BoardHistory, type: :model do
  let(:game) { Game.create(status: 'active') }
  
  describe 'validations' do
    it 'requires sfen, move_number, and branch' do
      history = BoardHistory.new(game: game)
      expect(history).not_to be_valid
      expect(history.errors[:sfen]).to include("can't be blank")
      expect(history.errors[:move_number]).to include("can't be blank")
    end
    
    it 'enforces uniqueness of move_number within game and branch' do
      BoardHistory.create!(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
        move_number: 1,
        branch: 'main'
      )
      
      duplicate = BoardHistory.new(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1',
        move_number: 1,
        branch: 'main'
      )
      
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:move_number]).to include("has already been taken")
    end
  end
  
  describe 'navigation methods' do
    before do
      # テストデータをセットアップ
      @history0 = BoardHistory.create!(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
        move_number: 0,
        branch: 'main'
      )
      
      @history1 = BoardHistory.create!(
        game: game,
        sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1',
        move_number: 1,
        branch: 'main'
      )
    end
    
    it 'returns previous board history' do
      expect(@history1.previous_board_history).to eq(@history0)
      expect(@history0.previous_board_history).to be_nil
    end
    
    it 'returns next board history' do
      expect(@history0.next_board_history).to eq(@history1)
      expect(@history1.next_board_history).to be_nil
    end
    
    it 'returns first and last board history' do
      expect(@history0.first_board_history).to eq(@history0)
      expect(@history1.first_board_history).to eq(@history0)
      
      expect(@history0.last_board_history).to eq(@history1)
      expect(@history1.last_board_history).to eq(@history1)
    end
  end
end
```

### 3.3 テストの実行とSwagger仕様の生成

Docker環境でテストを実行し、Swagger仕様を生成します：

```bash
# バックエンドコンテナ内でテストを実行
docker-compose exec backend rspec

# Swagger仕様を生成
docker-compose exec backend rails rswag:specs:swaggerize
```

### 4. フロントエンドの実装

#### APIクライアントの生成

OpenAPI仕様からTypeScriptクライアントを生成します：

```bash
# フロントエンドディレクトリで実行
cd frontend
npx swagger-typescript-api generate \
  --path ../backend/swagger/v1/openapi.yaml \
  --output ./src/services/api \
  --name "api.ts"
```

#### コンポーネントの作成

`frontend/src/components/MoveHistoryPanel.vue`ファイルを作成します：

```vue
<template>
  <div class="move-history-panel">
    <div class="panel-header">
      <h3>棋譜</h3>
      <div class="branch-selector">
        <select v-model="selectedBranch" @change="changeBranch">
          <option v-for="branch in branches" :key="branch" :value="branch">
            {{ branch }}
          </option>
        </select>
      </div>
    </div>
    
    <div class="move-list">
      <div 
        v-for="history in boardHistories" 
        :key="history.id"
        :class="['move-item', { 'current': history.move_number === currentMoveNumber }]"
        @click="navigateToMove(history.move_number)"
      >
        <span class="move-number">{{ history.move_number }}</span>
        <span class="notation">{{ history.notation || '開始局面' }}</span>
      </div>
    </div>
    
    <div class="navigation-controls">
      <button @click="navigateToFirst">|◀</button>
      <button @click="navigateToPrevious">◀</button>
      <button @click="navigateToNext">▶</button>
      <button @click="navigateToLast">▶|</button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue';
import { useBoardStore } from '@/stores/board';

const props = defineProps({
  gameId: {
    type: Number,
    required: true
  }
});

const emit = defineEmits(['move-navigated']);

const boardStore = useBoardStore();
const boardHistories = ref([]);
const currentMoveNumber = ref(0);
const selectedBranch = ref('main');
const branches = ref(['main']);

// 履歴の取得
const fetchHistories = async () => {
  try {
    const response = await boardStore.fetchBoardHistories(props.gameId, selectedBranch.value);
    boardHistories.value = response;
    currentMoveNumber.value = boardStore.currentMoveNumber;
  } catch (error) {
    console.error('Error fetching histories:', error);
  }
};

// 分岐リストの取得
const fetchBranches = async () => {
  try {
    const response = await boardStore.fetchBranches(props.gameId);
    branches.value = response.branches;
  } catch (error) {
    console.error('Error fetching branches:', error);
  }
};

// 指定した手数の局面に移動
const navigateToMove = async (moveNumber) => {
  try {
    await boardStore.navigateToMove(props.gameId, moveNumber, selectedBranch.value);
    currentMoveNumber.value = moveNumber;
    emit('move-navigated', moveNumber);
  } catch (error) {
    console.error('Error navigating to move:', error);
  }
};

// 最初の局面に移動
const navigateToFirst = async () => {
  const firstHistory = boardHistories.value.find(h => h.move_number === 0);
  if (firstHistory) {
    await navigateToMove(0);
  }
};

// 一手前の局面に移動
const navigateToPrevious = async () => {
  const prevMoveNumber = currentMoveNumber.value - 1;
  if (prevMoveNumber >= 0) {
    await navigateToMove(prevMoveNumber);
  }
};

// 一手先の局面に移動
const navigateToNext = async () => {
  const nextMoveNumber = currentMoveNumber.value + 1;
  const nextExists = boardHistories.value.some(h => h.move_number === nextMoveNumber);
  if (nextExists) {
    await navigateToMove(nextMoveNumber);
  }
};

// 最後の局面に移動
const navigateToLast = async () => {
  const lastHistory = [...boardHistories.value].sort((a, b) => b.move_number - a.move_number)[0];
  if (lastHistory) {
    await navigateToMove(lastHistory.move_number);
  }
};

// 分岐切り替え
const changeBranch = async () => {
  try {
    await boardStore.switchBranch(props.gameId, selectedBranch.value);
    await fetchHistories();
  } catch (error) {
    console.error('Error changing branch:', error);
  }
};

// コンポーネントマウント時に履歴と分岐を取得
onMounted(async () => {
  await fetchBranches();
  await fetchHistories();
});

// ゲームIDが変更されたら再取得
watch(() => props.gameId, async () => {
  await fetchBranches();
  await fetchHistories();
});
</script>

<style scoped>
.move-history-panel {
  width: 250px;
  border: 1px solid #ccc;
  border-radius: 4px;
  padding: 10px;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.panel-header h3 {
  margin: 0;
  font-size: 16px;
}

.move-list {
  max-height: 400px;
  overflow-y: auto;
  margin-bottom: 10px;
}

.move-item {
  padding: 5px;
  cursor: pointer;
  display: flex;
}

.move-item:hover {
  background-color: #f0f0f0;
}

.move-item.current {
  background-color: #e0f0ff;
  font-weight: bold;
}

.move-number {
  width: 30px;
}

.navigation-controls {
  display: flex;
  justify-content: space-between;
}

.navigation-controls button {
  flex: 1;
  margin: 0 2px;
  padding: 5px;
}
</style>
```

#### ストアの拡張

`frontend/src/stores/board.js`ファイルを更新または作成します：

```javascript
import { defineStore } from 'pinia';
import { BoardHistoryApi } from '@/services/api/api';

export const useBoardStore = defineStore('board', {
  state: () => ({
    game: null,
    board: null,
    boardHistories: [],
    currentMoveNumber: 0,
    maxMoveNumber: 0,
    availableBranches: ['main'],
    currentBranch: 'main'
  }),
  
  actions: {
    // 履歴の取得
    async fetchBoardHistories(gameId, branch = 'main') {
      try {
        const response = await BoardHistoryApi.getBoardHistories(gameId, branch);
        this.boardHistories = response.data;
        this.maxMoveNumber = this.boardHistories.length > 0 
          ? Math.max(...this.boardHistories.map(h => h.move_number))
          : 0;
        return this.boardHistories;
      } catch (error) {
        console.error('Error fetching board histories:', error);
        throw error;
      }
    },
    
    // 分岐リストの取得
    async fetchBranches(gameId) {
      try {
        const response = await BoardHistoryApi.getBranches(gameId);
        this.availableBranches = response.data.branches;
        return response.data;
      } catch (error) {
        console.error('Error fetching branches:', error);
        throw error;
      }
    },
    
    // 指定手数への移動
    async navigateToMove(gameId, moveNumber, branch = 'main') {
      try {
        const response = await BoardHistoryApi.navigateToMove(gameId, moveNumber, branch);
        this.board = { 
          id: response.data.board_id, 
          sfen: response.data.sfen 
        };
        this.currentMoveNumber = moveNumber;
        return response.data;
      } catch (error) {
        console.error('Error navigating to move:', error);
        throw error;
      }
    },
    
    // 分岐切り替え
    async switchBranch(gameId, branchName) {
      try {
        const response = await BoardHistoryApi.switchBranch(gameId, branchName);
        this.currentBranch = branchName;
        this.currentMoveNumber = response.data.current_move_number;
        return response.data;
      } catch (error) {
        console.error('Error switching branch:', error);
        throw error;
      }
    },
    
    // 駒を動かす（既存のメソッドを拡張）
    async makeMove(gameId, boardId, move, moveNumber = null, branch = null) {
      try {
        const payload = { move };
        if (moveNumber !== null) payload.move_number = moveNumber;
        if (branch !== null) payload.branch = branch;
        
        const response = await /* 既存のAPIコール */
        
        // 成功したら履歴を更新
        this.currentMoveNumber = response.data.move_number;
        this.currentBranch = response.data.branch;
        await this.fetchBoardHistories(gameId, this.currentBranch);
        
        return response.data;
      } catch (error) {
        console.error('Error making move:', error);
        throw error;
      }
    }
  }
});
```

#### APIクライアントの実装

`frontend/src/services/api/boardHistory.js`ファイルを作成します：

```javascript
import apiClient from './client';

export class BoardHistoryApi {
  // 履歴の取得
  static async getBoardHistories(gameId, branch = 'main') {
    return apiClient.get(`/api/v1/games/${gameId}/board_histories`, { 
      params: { branch } 
    });
  }

  // 分岐リストの取得
  static async getBranches(gameId) {
    return apiClient.get(`/api/v1/games/${gameId}/board_histories/branches`);
  }

  // 指定した手数への移動
  static async navigateToMove(gameId, moveNumber, branch = 'main') {
    return apiClient.post(`/api/v1/games/${gameId}/navigate_to/${moveNumber}`, null, {
      params: { branch }
    });
  }

  // 分岐切り替え
  static async switchBranch(gameId, branchName) {
    return apiClient.post(`/api/v1/games/${gameId}/switch_branch/${branchName}`);
  }
}
```

### 5. デプロイとテスト

#### 5.1 バックエンドのテスト実行

```bash
# バックエンドコンテナ内でテストを実行
docker-compose exec backend rspec
```

#### 5.2 フロントエンドのテスト実行

```bash
# フロントエンドコンテナ内でテストを実行
docker-compose exec frontend npm run test
```

#### 5.3 手動テスト

1. アプリケーションを起動
   ```bash
   # Docker環境を起動（既に起動している場合は不要）
   docker-compose up -d
   ```

2. 新しいゲームを作成
3. 駒を動かして履歴が生成されることを確認
4. 過去の局面に戻れることを確認
5. 分岐が作成できることを確認

#### 5.4 本番環境へのデプロイ

Docker環境での本番デプロイ手順：

1. 本番環境のDockerイメージをビルド
   ```bash
   docker-compose -f docker-compose.prod.yml build
   ```

2. データベースマイグレーションの実行
   ```bash
   docker-compose -f docker-compose.prod.yml exec backend rails db:migrate
   ```

3. サービスの起動
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

## 注意点

### セキュリティ

- 認証・認可の実装
- 入力値のバリデーション
- CSRFトークンの適用

### パフォーマンス

- 長い対局履歴のページネーション
- クエリの最適化
- キャッシュの活用

### フロントエンド

- 局面移動時のアニメーション実装
- 分岐ビジュアライゼーション
- スタイリングの調整

### バックエンド

- エラーハンドリングの充実
- ロギングの実装
- トランザクション管理

### Docker環境での開発に関する注意点

- コンテナ間の通信（ネットワーク設定）の確認
- ボリュームマウントによるコード変更の反映
- 環境変数の適切な設定
- コンテナのリソース制限（メモリ、CPU）の確認

## 実装後の確認項目

- [ ] 全ての機能が正常に動作するか
- [ ] エラーケースでも適切に挙動するか
- [ ] パフォーマンスに問題はないか
- [ ] ブラウザの互換性に問題はないか
- [ ] モバイル対応は十分か
- [ ] アクセシビリティに配慮されているか
- [ ] Dockerコンテナ内で正常に動作するか

## 拡張ポイント

- 分岐ごとの名前付け機能
- 局面のブックマーク機能
- 棋譜のエクスポート/インポート機能
- コメントや評価の追加
- AIによる指し手評価連携

## 工数見積もり

### バックエンド実装

| 作業項目 | 工数 (人日) |
|---------|------------|
| データベースマイグレーション作成 | 0.5 |
| BoardHistoryモデル実装 | 1.0 |
| BoardHistoriesコントローラ実装 | 2.0 |
| Movesコントローラの拡張 | 1.0 |
| ルーティング設定 | 0.5 |
| Rswag API仕様作成 | 1.0 |
| ユニットテスト作成 | 1.5 |
| 統合テスト作成 | 1.0 |
| **小計** | **7.5** |

### フロントエンド実装

| 作業項目 | 工数 (人日) |
|---------|------------|
| APIクライアント生成 | 0.5 |
| ストア実装 (Vuex/Pinia) | 1.0 |
| MoveHistoryPanelコンポーネント作成 | 2.0 |
| ShogiBoardコンポーネント拡張 | 1.0 |
| スタイリング | 1.0 |
| コンポーネントテスト | 1.0 |
| E2Eテスト | 1.0 |
| **小計** | **7.5** |

### その他作業

| 作業項目 | 工数 (人日) |
|---------|------------|
| 機能統合・調整 | 1.0 |
| デバッグ・不具合修正 | 2.0 |
| ドキュメント更新 | 0.5 |
| **小計** | **3.5** |

### バッファー

| 作業項目 | 工数 (人日) |
|---------|------------|
| 予期せぬ問題対応バッファー (20%) | 3.6 |
| 環境構築・ツール対応 | 0.4 |
| Dockerコンテナ関連の調整 | 1.0 |
| **小計** | **5.0** |

### 合計工数

| 項目 | 工数 (人日) |
|------|------------|
| バックエンド実装 | 7.5 |
| フロントエンド実装 | 7.5 |
| その他作業 | 3.5 |
| バッファー | 5.0 |
| **合計** | **23.5** |

**合計: 約23.5人日**（約4.7週間）

### 備考

- 上記は基本機能の実装に必要な工数であり、追加機能（局面へのコメント追加、棋譜のエクスポート/インポートなど）は含まれていません
- 開発者のスキルレベルにより、工数は変動する可能性があります
- チーム開発の場合、コミュニケーションコストが追加で必要になります
- 仕様変更が発生した場合、工数が増加する可能性があります
- バッファーは予期せぬ障害や問題解決、他システムとの連携調整などに使用されます
- Docker環境特有の問題（コンテナ間通信、ボリュームマウント、環境変数など）に対応するための時間も考慮しています 