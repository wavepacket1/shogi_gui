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
          status: { type: :string, enum: ['active', 'finished', 'pause'] }
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

        let(:game) { { status: 'active' } }
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
            status: { type: :string, enum: ['success', 'failed'] },
            game_id: { type: :integer },
            board_id: { type: :integer }
          },
          required: ['game_id', 'status', 'board_id']
        
        let(:game_id) { Game.create(status: 'active').id }
        let(:board_id) { Board.create(game_id:).id }
        run_test!
      end

      response '404', 'game not found' do 
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']
        
        let(:id) { Game.maximum(:id).to_i + 1 }
        run_test!
      end
    end
  end

  path '/api/v1/games/:id/resign' do
    post '投了を行う' do
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

        let(:id) { create(:game, status: 'active').id }
        run_test!
      end

      response '401', '未認証ユーザーはアクセスできないこと' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']

        let(:id) { create(:game, status: 'active').id }
        run_test!
      end

      response '403', '対局参加者以外は投了できないこと' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']

        let(:id) { create(:game, status: 'active').id }
        run_test!
      end

      response '409', '既に終了した対局では投了できないこと' do
        schema type: :object,
          properties: {
            status: { type: :string },
            message: { type: :string }
          },
          required: ['status', 'message']

        let(:id) { create(:game, status: 'finished').id }
        run_test!
      end
    end
  end
end