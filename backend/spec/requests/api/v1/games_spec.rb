require 'rails_helper'

RSpec.describe 'Games API', type: :request do
  describe 'POST /api/v1/games' do
    it 'ゲームを作成できる' do
      post '/api/v1/games', params: { status: 'active' }
      
      expect(response).to have_http_status(:created)
      expect(Game.count).to eq(1)
      
      # レスポンスの形式を検証
      expect(json).to include(
        'id' => be_kind_of(Integer),
        'status' => 'active'
      )
    end

    it '不正なパラメータでは作成できない' do
      post '/api/v1/games', params: { status: 'invalid' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(Game.count).to eq(0)
      expect(json).to include('error' => be_kind_of(String))
    end
  end

  describe 'GET /api/v1/games/:id' do
    let(:game) { create(:game) }
    let(:path) { "/api/v1/games/#{game.id}" }

    it 'ゲームを取得できる' do
      get path
      
      expect(response).to have_http_status(:ok)
      expect(json).to include(
        'id' => game.id,
        'status' => game.status
      )
    end
  end
end 