
require 'swagger_helper'

RSpec.describe 'api/v1/games', type: :request do
    path '/api/v1/games' do

        post('ゲーム作成') do
            tags 'Games'
            consumes 'application/json'
            produces 'application/json'

            parameter name: :game, in: :body, schema: {
                type: :object, 
                properties: {
                    status: {
                        type: :string, 
                        enum: ['active', 'completed'],
                        example: 'active',
                        description: 'ゲームの状態。activeは進行中、completedは終了済みを表します'
                    }
                },
                required: 'status'
            }

            response '201', 'ゲームが作成されました' do 
                schema type: :object,
                    properties: {
                        id: { type: :integer, example: 1 },
                        status: { type: :string, example: 'active' },
                    }
                
                let(:game) {{ status: 'active' }}
                run_test!
            end

            response '422', '無効なパラメータ' do
                schema type: :object, 
                    properties: {
                        error: { type: :string, example: "Validation failed" }
                    }

                let(:game) { { status: '' }}
                run_test!
            end
        end
    end
end