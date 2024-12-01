
require 'swagger_helper'

RSpec.describe 'api/v1/pieces', type: :request do
    path '/api/v1/pieces/{id}' do
        patch('駒の更新') do
            tags 'Pieces'
            consumes 'application/json'
            parameter name: :id, in: :path, type: :integer, description: '駒ID'
            parameter name: :piece, in: :body, schema: {
                type: :object,
                properties: {
                position_x: { type: :integer, minimum: 1, maximum: 9 },
                position_y: { type: :integer, minimum: 1, maximum: 9 }
                },
                required: ['position_x', 'position_y']
            }

            response(200, '更新成功') do
                schema type: :object,
                    properties: {
                        status: { type: :string },
                        piece: {
                        type: :object,
                        properties: {
                            id: { type: :integer },
                            position_x: { type: :integer },
                            position_y: { type: :integer }
                        },
                        required: ['id', 'position_x', 'position_y']
                        }
                    },
                    required: ['status', 'piece']

                let(:piece_record) { Piece.create(piece_type: 'P', owner: 'b', position_x: 1, position_y: 1) }
                let(:id) { piece_record.id }
                let(:piece) { { position_x: 2, position_y: 2 } }
                run_test!
            end

            response(404, '駒が見つかりません') do
                schema type: :object,
                    properties: {
                        status: { type: :string },
                        message: { type: :string }
                    },
                    required: ['status', 'message']

                let(:id) { 'invalid' }
                let(:piece) { { position_x: 2, position_y: 2 } }
                run_test!
            end

            response(422, '無効なリクエスト') do
                schema type: :object,
                    properties: {
                        status: { type: :string },
                        message: { type: :string }
                    },
                    required: ['status', 'message']

                let(:piece_record) { Piece.create(piece_type: 'P', owner: 'b', position_x: 1, position_y: 1) }
                let(:id) { piece_record.id }
                let(:piece) { { position_x: 10, position_y: 10 } }
                run_test!
            end
        end
    end
end