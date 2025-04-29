require 'swagger_helper'

describe 'Games API' do
  path '/api/v1/games' do
    post 'ゲームを作成する' do
      tags 'Games'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :game, in: :body, schema: {
        type: :object,
        properties: {
          status: { type: :string, enum: ['active', 'finished', 'pause'] },
          mode: { type: :string, enum: ['play', 'edit', 'study'] }
        },
        required: ['status']
      }

      response '201', 'game created' do
        schema type: :object,
          properties: {
            game_id: { type: :integer },
            status: { type: :string, enum: ['active', 'finished', 'pause'] },
            board_id: { type: :integer }
          },
          required: ['game_id', 'status', 'board_id']

        let(:game) { { status: 'active', mode: 'play' } }
        run_test!
      end

      response '422', 'invalid request' do
        schema type: :object,
          properties: {
            error: { type: :string }
          }
        
        let(:game) { { status: 'invalid' } }
        run_test!
      end
    end
  end

  path '/api/v1/games/{game_id}/boards/{board_id}/nyugyoku_declaration' do 
    post '入玉宣言を行う' do 
      tags 'Games'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :game_id, in: :path, type: :integer, description: 'Game ID'
      parameter name: :board_id, in: :path, type: :integer, description: 'Board ID'
      
      response '200', 'nyugyoku declared' do 
        schema type: :object,
          properties: {
            status: { type: :string, enum: ['success', 'failed'] }
          }
        
        let(:game) { create(:game, status: 'active', mode: 'play') }
        let(:board) { create(:board, game: game, sfen: Board.default_sfen) }
        let(:game_id) { game.id }
        let(:board_id) { board.id }
        run_test!
      end

      response '404', 'game not found' do 
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']
        
        let(:game_id) { Game.maximum(:id).to_i + 1 }
        let(:board_id) { 1 }
        run_test!
      end
    end
  end

  # 投了関連のテストは他の改修が必要なためスキップ
  path '/api/v1/games/{id}/resign' do
    post '投了を行う', :skip => '投了機能は別途改修が必要なため' do
      tags 'Games'
      consumes 'application/json'
      produces 'application/json'

      parameter name: :id, in: :path, type: :integer, description: 'Game ID'

      response '200', '投了が成功すること' do
        schema type: :object,
          properties: {
            status: { type: :string, enum: ['success', 'failed'] },
            game_status: { type: :string, enum: ['finished'] },
            winner: { type: :string },
            ended_at: { type: :string }
          },
          required: ['status', 'game_status', 'winner', 'ended_at']

        let(:game) { create(:game, status: 'active', mode: 'play') }
        let(:board) { create(:board, game: game, sfen: Board.default_sfen) }
        let(:id) { game.id }
        run_test!
      end

      response '401', '未認証ユーザーはアクセスできないこと' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']

        let(:game) { create(:game, status: 'active', mode: 'play') }
        let(:id) { game.id }
        run_test!
      end

      response '403', '対局参加者以外は投了できないこと' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']

        let(:game) { create(:game, status: 'active', mode: 'play') }
        let(:id) { game.id }
        run_test!
      end

      response '409', '既に終了した対局では投了できないこと' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']

        let(:game) { create(:game, status: 'finished', mode: 'play') }
        let(:id) { game.id }
        run_test!
      end
    end
  end

  path '/api/v1/games/{id}/mode' do
    post 'ゲームモードを変更する' do
      tags 'Games'
      consumes 'application/json'
      produces 'application/json'
      
      parameter name: :id, in: :path, type: :integer, description: 'Game ID'
      parameter name: :mode, in: :query, type: :string, 
                description: '設定するモード', required: true,
                schema: { type: :string, enum: ['play', 'edit', 'study'] }
      
      response '200', 'モードが変更されました' do
        schema type: :object,
          properties: {
            game_id: { type: :integer },
            mode: { type: :string, enum: ['play', 'edit', 'study'] },
            status: { type: :string },
            updated_at: { type: :string, format: 'date-time' }
          },
          required: ['game_id', 'mode', 'status', 'updated_at']
          
        let(:game) { create(:game, status: 'active', mode: 'play') }
        let(:id) { game.id }
        let(:mode) { 'edit' }
        
        run_test!
      end
      
      response '404', 'ゲームが見つかりません', skip: true do
        schema type: :object,
          properties: {
            error: { type: :string }
          },
          required: ['error']
          
        # ゲームIDを動的に生成して確実に存在しないIDを使用
        let(:nonexistent_id) { Game.maximum(:id).to_i + 999 }
        let(:id) { nonexistent_id }
        let(:mode) { 'edit' }
        
        run_test!
      end
    end
  end
end