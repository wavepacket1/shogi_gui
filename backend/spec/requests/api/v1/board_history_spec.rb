require 'rails_helper'

RSpec.describe "Api::V1::BoardHistories", type: :request do
  let!(:game) { Game.create!(status: 'active') }
  let!(:board) { Board.create!(game: game, sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0') }
  
  before do
    # 履歴データをセットアップ
    BoardHistory.create!(
      game: game,
      sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
      move_number: 0,
      branch: 'main'
    )
    
    BoardHistory.create!(
      game: game,
      sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1',
      move_number: 1,
      branch: 'main'
    )
    
    # 別の分岐も作成
    BoardHistory.create!(
      game: game,
      sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0',
      move_number: 0,
      branch: 'branch_1'
    )
    
    BoardHistory.create!(
      game: game,
      sfen: 'lnsgkgsnl/1r5b1/p1ppppppp/1p7/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1',
      move_number: 1,
      branch: 'branch_1'
    )
  end
  
  describe "GET /api/v1/games/:game_id/board_histories" do
    it "returns all board histories for a game and branch" do
      get "/api/v1/games/#{game.id}/board_histories", params: { branch: 'main' }
      
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json.size).to eq(2)
      expect(json[0]['move_number']).to eq(0)
      expect(json[1]['move_number']).to eq(1)
      expect(json[0]['branch']).to eq('main')
    end
    
    it "returns 404 for non-existent game" do
      get "/api/v1/games/999/board_histories"
      expect(response).to have_http_status(404)
    end
  end
  
  describe "GET /api/v1/games/:game_id/board_histories/branches" do
    it "returns all branches for a game" do
      get "/api/v1/games/#{game.id}/board_histories/branches"
      
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json['branches']).to include('main', 'branch_1')
    end
  end
  
  describe "POST /api/v1/games/:game_id/navigate_to/:move_number" do
    it "navigates to a specific move number" do
      post "/api/v1/games/#{game.id}/navigate_to/1", params: { branch: 'main' }
      
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json['move_number']).to eq(1)
      
      # ボードの状態が更新されていることを確認
      board.reload
      expect(board.sfen).to eq('lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1')
    end
    
    it "returns 404 for non-existent move number" do
      post "/api/v1/games/#{game.id}/navigate_to/99", params: { branch: 'main' }
      expect(response).to have_http_status(404)
    end
  end
  
  describe "POST /api/v1/games/:game_id/switch_branch/:branch_name" do
    it "switches to a different branch" do
      post "/api/v1/games/#{game.id}/switch_branch/branch_1"
      
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json['branch']).to eq('branch_1')
      expect(json['current_move_number']).to eq(1)
      
      # ボードの状態が更新されていることを確認
      board.reload
      expect(board.sfen).to eq('lnsgkgsnl/1r5b1/p1ppppppp/1p7/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL w - 1')
    end
    
    it "returns 404 for non-existent branch" do
      post "/api/v1/games/#{game.id}/switch_branch/non_existent_branch"
      expect(response).to have_http_status(404)
    end
  end
end
