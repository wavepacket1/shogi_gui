
require 'swagger_helper'

RSpec.describe 'api/v1/games', type: :request do
    path '/api/v1/games' do

        post('ゲーム作成') do
            tags 'Games'
            consumes 'application/json'
            parameter name: :game, in: :body, schema: {
                type: :object,
                properties: {
                name: { type: :string }
                },
                required: ['name']
            }

            response(201, 'ゲームが作成されました') do
                schema type: :object,
                    properties: {
                        status: { type: :string },
                        game: {
                        type: :object,
                        properties: {
                            id: { type: :integer },
                            name: { type: :string },
                            status: { type: :string }
                        },
                        required: ['id', 'name', 'status']
                        },
                        board: {
                        type: :object,
                        properties: {
                            id: { type: :integer },
                            name: { type: :string },
                            active_player: { type: :string }
                        },
                        required: ['id', 'name', 'active_player']
                        }
                    },
                    required: ['status', 'game', 'board']

                run_test!
            end

            response(422, '無効なリクエスト') do
                schema type: :object,
                    properties: {
                        status: { type: :string },
                        message: { type: :string }
                    },
                    required: ['status', 'message']

                run_test!
            end
        end
    end
end