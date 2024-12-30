require 'swagger_helper'

describe 'Games API' do
  path '/api/v1/games' do
    post 'ゲームを作成する' do
      tags 'Games'
      consumes 'application/json'
      parameter name: :game, in: :body, schema: {
        type: :object,
        properties: {
          status: { type: :string, enum: ['active', 'completed'] }
        }
      }

      response '201', 'game created' do
        let(:game) { { status: 'active' } }
        run_test!
      end
    end
  end
end