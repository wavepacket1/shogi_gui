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

                let(:game) { create(:game, status: 'active', mode: 'play') }
                let(:board) { create(:board, game: game, sfen: Board.default_sfen) }
                let(:id) { board.id }
                
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

    path '/api/v1/boards' do
        post('盤面を保存する') do
            tags 'Boards'
            consumes 'application/json'
            produces 'application/json'
            description '通常の対局、または編集モードでの盤面を保存します'
            
            parameter name: :params, in: :body, schema: {
                type: :object,
                required: ['board'],
                properties: {
                    board: {
                        type: :object,
                        required: ['game_id', 'sfen'],
                        properties: {
                            game_id: { type: :integer, description: 'ゲームID' },
                            sfen: { type: :string, description: '盤面情報のSFEN文字列' }
                        }
                    },
                    mode: {
                        type: :string,
                        enum: ['edit'],
                        description: '編集モードを指定（editの場合は編集モードとして扱う）'
                    }
                }
            }

            response(201, '盤面保存成功') do
                let(:game) { create(:game, status: 'active', mode: 'edit') }
                let(:params) {
                    {
                        board: {
                            game_id: game.id,
                            sfen: 'lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0'
                        },
                        mode: 'edit'
                    }
                }
                
                schema type: :object,
                    properties: {
                        status: { type: :string, example: 'success' },
                        board: {
                            type: :object,
                            properties: {
                                id: { type: :integer },
                                game_id: { type: :integer },
                                sfen: { type: :string },
                                custom_position: { 
                                    type: :boolean,
                                    description: '編集モードで作成されたカスタム局面かどうか' 
                                },
                                updated_at: { type: :string, format: 'date-time' }
                            }
                        }
                    }
                
                run_test!
            end
            
            response(422, 'バリデーションエラー') do
                let(:game) { create(:game, status: 'active', mode: 'edit') }
                let(:params) {
                    {
                        board: {
                            game_id: game.id,
                            sfen: '不正なSFEN'
                        },
                        mode: 'edit'
                    }
                }
                
                schema type: :object,
                    properties: {
                        status: { type: :string, example: 'error' },
                        message: { type: :string }
                    }
                
                run_test!
            end
        end
    end

    path '/api/v1/boards/default' do
        get('デフォルトボードの取得') do
            tags 'Boards'
            produces 'application/json'

            response(200, '成功') do
                schema type: :object,
                    properties: {
                        sfen: { type: :string },
                        legal_flag: { type: :boolean }
                    },
                    required: ['sfen', 'legal_flag']

                run_test!
            end
        end
    end
end