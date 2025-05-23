require 'swagger_helper'

RSpec.describe 'API::V1::Moves', type: :request do 
    path '/api/v1/games/{game_id}/boards/{board_id}/move' do 
        patch '駒の移動API' do 
            tags 'Moves'
            consumes 'application/json'
            produces 'application/json'

            parameter name: :game_id, in: :path, type: :integer, description: 'Game ID'
            parameter name: :board_id, in: :path, type: :integer, description: 'Board ID'
            parameter name: :move_number, in: :query, type: :integer, required: false, description: '現在の手数（分岐作成用）'
            parameter name: :branch, in: :query, type: :string, required: false, description: '現在の分岐名（分岐作成用）'

            parameter name: :move, in: :body, schema: {
                type: :object,
                properties: {
                    move: { type: :string, description: '指し手の表記', example: '7g7f' }
                },
                required: ['move']
            }

            response '200', 'Board updated successfully' do 
                schema type: :object,
                    properties: {
                        status: { type: :boolean, example: true },
                        is_checkmate: { type: :boolean, example: false },
                        is_repetition: { type: :boolean, example: false },
                        is_repetition_check: { type: :boolean, example: false },
                        board_id: { type: :integer, example: 123 },
                        sfen: { type: :string, example: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0' },
                        move_number: { type: :integer, example: 1 },
                        branch: { type: :string, example: 'main' },
                        move_sfen: { 
                            type: :string, 
                            example: '7g7f',
                            description: '前局面からの指し手情報（SFEN形式）'
                        },
                        notation: { 
                            type: :string, 
                            example: '▲7六歩',
                            description: '棋譜表記（日本語形式）'
                        }
                    }
                
                let(:game_id) { 1 }
                let(:board_id) { 123 }
                let(:move) { { move: '7g7f' }}

                run_test!
            end

            response '422', 'Invalid move or parameters' do 
                schema type: :object,
                    properties: {
                        status: { type: :boolean, example: false },
                        message: { type: :string, example: 'Invalid move: 8h2b+' },
                        board_id: { type: :integer, example: 123 },
                        sfen: { type: :string, example: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0' }
                    }

                let(:game_id) { 1 }
                let(:board_id) { 123 }
                let(:move) { { move: 'invalid_move' }}

                run_test!
            end
        end
    end
end