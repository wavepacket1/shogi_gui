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
    it "returns all branch names for a game" do
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
      expect(json['game_id']).to eq(game.id)
    end
  end
  
  describe "POST /api/v1/games/:game_id/switch_branch/:branch_name" do
    it "switches to a different branch" do
      post "/api/v1/games/#{game.id}/switch_branch/branch_1"
      
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json['branch']).to eq('branch_1')
      expect(json['game_id']).to eq(game.id)
    end
  end

  describe "POST /api/v1/games/:game_id/board_histories/:move_number/branches" do
    context "分岐作成" do
      it "creates a new branch from specified move" do
        post "/api/v1/games/#{game.id}/board_histories/1/branches", params: {
          branch_name: 'new-branch',
          source_branch: 'main'
        }
        
        expect(response).to have_http_status(201)
        json = JSON.parse(response.body)
        expect(json['branch_name']).to eq('new-branch')
        expect(json['move_number']).to eq(1)
        expect(json['source_branch']).to eq('main')
        
        # 新しい分岐に履歴がコピーされていることを確認
        new_branch_histories = game.board_histories.where(branch: 'new-branch')
        expect(new_branch_histories.count).to eq(2) # 0手目と1手目
        expect(new_branch_histories.pluck(:move_number)).to match_array([0, 1])
      end

      it "auto-generates branch name when not provided" do
        post "/api/v1/games/#{game.id}/board_histories/0/branches", params: {
          source_branch: 'main'
        }
        
        expect(response).to have_http_status(201)
        json = JSON.parse(response.body)
        expect(json['branch_name']).to match(/\Abranch-\d+\z/)
      end

      it "returns error for invalid branch name" do
        post "/api/v1/games/#{game.id}/board_histories/1/branches", params: {
          branch_name: 'invalid@name',
          source_branch: 'main'
        }
        
        expect(response).to have_http_status(400)
        json = JSON.parse(response.body)
        expect(json['error']).to include('英数字と-_のみ使用できます')
      end

      it "returns error for duplicate branch name" do
        post "/api/v1/games/#{game.id}/board_histories/1/branches", params: {
          branch_name: 'branch_1',
          source_branch: 'main'
        }
        
        expect(response).to have_http_status(400)
        json = JSON.parse(response.body)
        expect(json['error']).to include('同じ名前の分岐が既に存在します')
      end

      it "returns error for non-existent move number" do
        post "/api/v1/games/#{game.id}/board_histories/99/branches", params: {
          branch_name: 'new-branch',
          source_branch: 'main'
        }
        
        expect(response).to have_http_status(404)
        json = JSON.parse(response.body)
        expect(json['error']).to include('指定された局面が見つかりません')
      end
    end
  end

  describe "DELETE /api/v1/games/:game_id/branches/:branch_name" do
    context "分岐削除" do
      before do
        # テスト用のコメントも作成
        history = game.board_histories.where(branch: 'branch_1').first
        history.comments.create!(content: 'Test comment')
      end

      it "deletes a branch and its histories" do
        expect {
          delete "/api/v1/games/#{game.id}/branches/branch_1"
        }.to change { game.board_histories.where(branch: 'branch_1').count }.from(2).to(0)
        
        expect(response).to have_http_status(200)
        json = JSON.parse(response.body)
        expect(json['message']).to include('分岐「branch_1」を削除しました')
        expect(json['deleted_histories']).to eq(2)
        expect(json['deleted_comments']).to eq(1)
      end

      it "returns error when trying to delete main branch" do
        delete "/api/v1/games/#{game.id}/branches/main"
        
        expect(response).to have_http_status(400)
        json = JSON.parse(response.body)
        expect(json['error']).to include('main分岐は削除できません')
      end

      it "returns error for non-existent branch" do
        delete "/api/v1/games/#{game.id}/branches/non-existent"
        
        expect(response).to have_http_status(404)
        json = JSON.parse(response.body)
        expect(json['error']).to include('分岐が見つかりません')
      end
    end
  end
end
