
require 'swagger_helper'

RSpec.describe 'api/v1/boards', type: :request do
    path '/api/v1/boards/{id}' do
        get('ボードの取得') do
            tags 'Boards'
            produces 'application/json'
            parameter name: :id, in: :path, type: :integer, description: 'ボードID'

            response(200, '成功') do
                schema type: :object,
                    properties: {
                        sfen: { type: :string },
                        legal_flag: { type: :boolean }
                    },
                    required: ['sfen', 'legal_flag']

                let(:id) { Board.create(name: 'Game 1', active_player: 'b').id }
                run_test!
            end

            response(404, 'ボードが見つかりません') do
                schema type: :object,
                    properties: {
                        status: { type: :string },
                        message: { type: :string }
                    },
                    required: ['status', 'message']

                let(:id) { Board.maximum(:id).to_i + 1 }
                run_test!
            end
        end
    end
end