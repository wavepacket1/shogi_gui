module Api
    module V1
        class BoardsController < ApplicationController
            before_action :set_board, only: [:show]

            # GET /api/v1/boards/{id}
            # @return [JSON] 盤面情報
            def show
                render json: {
                    sfen: @board.to_sfen,
                    legal_flag: true
                }, status: :ok
            end

            # POST /api/v1/boards
            # @param [JSON] board 盤面情報
            # @param [String] mode 編集モード指定（editの場合は編集モードとして扱う）
            # @return [JSON] 保存された盤面情報
            def create
                mode = params[:mode]
                
                @board = Board.new(board_params)
                @board.custom_position = (mode == 'edit')
                
                # 編集モードの場合はバリデーションを緩和
                validator_method = (mode == 'edit') ? :basic_valid? : :valid?
                
                if Validator.send(validator_method, @board.sfen)
                    if @board.save
                        render json: { 
                            status: 'success', 
                            board: {
                                id: @board.id,
                                game_id: @board.game_id,
                                sfen: @board.sfen,
                                custom_position: @board.custom_position,
                                updated_at: @board.updated_at
                            }
                        }, status: :created
                    else
                        render json: { status: 'error', message: @board.errors.full_messages.join(", ") }, status: :unprocessable_entity
                    end
                else
                    render json: { status: 'error', message: '盤面の形式が不正です' }, status: :unprocessable_entity
                end
            end

            # GET /api/v1/boards/default
            # @return [JSON] デフォルト盤面情報
            def default 
                render json: {
                    sfen: Board.default_sfen,
                    legal_flag: true
                }
            end

            private 

            def set_board
                @board = Board.find(params[:id])
            rescue ActiveRecord::RecordNotFound
                render json: { status: 'error', message: 'ボードが見つかりません。' }, status: :not_found
            end

            def board_params
                params.require(:board).permit(:game_id, :sfen)
            end
        end
    end
end