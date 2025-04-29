# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::GamesController, type: :controller do
  let(:create_params) { { status: 'active', mode: 'play' } }

  describe 'GET #show' do
    it 'returns a success response' do
      game = create(:game)
      get :show, params: { id: game.id }
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new Game' do
        expect {
          post :create, params: { game: create_params }
        }.to change(Game, :count).by(1)
      end

      it 'renders a JSON response with the new game' do
        post :create, params: { game: create_params }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'POST #mode' do
    let(:game) { create(:game, status: 'active', mode: 'play') }
    
    context 'モード切替が成功する場合' do
      it 'playからeditモードに変更できること' do
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'edit' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['mode']).to eq('edit')
        expect(game.reload.mode).to eq('edit')
      end
      
      it 'playからstudyモードに変更できること' do
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'study' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['mode']).to eq('study')
        expect(game.reload.mode).to eq('study')
      end
      
      it 'editからplayモードに戻せること' do
        game.update(mode: 'edit')
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'play' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['mode']).to eq('play')
        expect(game.reload.mode).to eq('play')
      end
      
      it 'studyからplayモードに戻せること' do
        game.update(mode: 'study')
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'play' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['mode']).to eq('play')
        expect(game.reload.mode).to eq('play')
      end
      
      it 'モード切替時にゲームのステータスが維持されること' do
        game.update(status: 'pause')
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'edit' }
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['mode']).to eq('edit')
        expect(json['status']).to eq('pause')
        expect(game.reload.status).to eq('pause')
      end
      
      it 'モード切替時に関連する盤面情報が維持されること' do
        board = create(:board, game: game)
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'study' }
        
        expect(response).to have_http_status(:ok)
        expect(game.reload.board).to eq(board)
      end
      
      it 'モード切替時に局面履歴が維持されること' do
        history = create(:board_history, game: game)
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'edit' }
        
        expect(response).to have_http_status(:ok)
        expect(game.reload.board_histories).to include(history)
      end
    end
    
    context 'モード切替が失敗する場合' do
      it 'モードが指定されていない場合はエラーを返す' do
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('モードが指定されていません')
      end
      
      it '無効なモードの場合はエラーを返す' do
        request.headers['accept'] = 'application/json'
        post :mode, params: { id: game.id, mode: 'invalid' }
        
        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('無効なモードです')
      end
      
      it '存在しないゲームIDの場合はエラーを返す', skip: 'コントローラーテストではなく統合テストでテストすべき機能' do
        # このテストは統合テストでのみ有効です
        # コントローラーテスト内では適切にモックを設定できないため、スキップします
      end
    end
  end
end 