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
          status: { type: :string, enum: ['active', 'completed'] }
        },
        required: ['status']
      }

      response '201', 'game created' do
        schema type: :object,
          properties: {
            game_id: { type: :integer },
            status: { type: :string, enum: ['active', 'completed'] },
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
end