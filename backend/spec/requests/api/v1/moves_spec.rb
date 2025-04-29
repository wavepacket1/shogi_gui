require 'rails_helper'

RSpec.describe 'Api::V1::Moves', type: :request do
  # テスト用のゲームとボードを作成
  let(:game) { create(:game, status: 'active') }
  let(:board) { create(:board, game: game) }
  
  before do
    # 初期局面の履歴を作成
    create(:board_history, 
      game: game, 
      sfen: board.sfen, 
      move_number: 0, 
      branch: 'main'
    )
  end
  
  describe 'PATCH /api/v1/games/:game_id/boards/:board_id/move' do
    it '有効な指し手で盤面を更新できること' do
      patch "/api/v1/games/#{game.id}/boards/#{board.id}/move", params: {
        move: '7g7f'
      }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to be true
      expect(json['board_id']).not_to eq(board.id) # 新しいボードIDが発行される
      expect(json['move_number']).to eq(1)
      expect(json['branch']).to eq('main')
      expect(game.board_histories.count).to eq(2) # 初期局面 + 1手
    end
    
    it '手数と分岐を指定して指し手を実行できること' do
      patch "/api/v1/games/#{game.id}/boards/#{board.id}/move", params: {
        move: '7g7f',
        move_number: 0,
        branch: 'main'
      }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to be true
      expect(json['move_number']).to eq(1)
      expect(json['branch']).to eq('main')
    end
    
    it '手の再生成ができること' do
      # 最初の手を指す
      patch "/api/v1/games/#{game.id}/boards/#{board.id}/move", params: {
        move: '7g7f'
      }
      
      # 手数1の履歴を作成
      second_board = Board.find_by(id: JSON.parse(response.body)['board_id'])
      
      # 2手目の指し手
      patch "/api/v1/games/#{game.id}/boards/#{second_board.id}/move", params: {
        move: '3c3d',
        move_number: 1,
        branch: 'main'
      }
      
      # 最初の手に戻る（手数0の局面）
      post "/api/v1/games/#{game.id}/navigate_to/0", params: {
        branch: 'main'
      }
      
      # 手数0から再度手を指す
      patch "/api/v1/games/#{game.id}/boards/#{board.id}/move", params: {
        move: '9g9f',
        move_number: 0,
        branch: 'main'
      }
      
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      # 手が正常に処理されることを確認
      expect(json['status']).to be true
      expect(game.board_histories.where(branch: 'main').count).to be >= 2
    end
    
    it '不正な指し手の場合はエラーになること' do
      patch "/api/v1/games/#{game.id}/boards/#{board.id}/move", params: {
        move: 'invalid_move'
      }
      
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['status']).to be false
    end
    
    it '存在しないゲームIDの場合はエラーになること' do
      patch "/api/v1/games/9999/boards/#{board.id}/move", params: {
        move: '7g7f'
      }
      
      expect(response).to have_http_status(:not_found)
    end
    
    it '存在しないボードIDの場合はエラーになること' do
      patch "/api/v1/games/#{game.id}/boards/9999/move", params: {
        move: '7g7f'
      }
      
      expect(response).to have_http_status(:not_found)
    end
  end
end 