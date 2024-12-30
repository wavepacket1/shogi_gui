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
end