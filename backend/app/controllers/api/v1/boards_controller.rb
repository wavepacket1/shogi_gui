module Api
    module V1
        class BoardsController < ApplicationController
            before_action :set_board, only: [:show]

            def show
                render json: {
                    sfen: @board.to_sfen,
                    legal_flag: true
                }, status: :ok
            end

            def create
                @board = Board.new(board_params)
                @board.active_player = 'b' # 初期プレイヤーを設定
                if @board.save 
                    render json: { status: 'success', board: @board }, status: :created
                else
                    render json: { status: 'error', message: @board.errors.full_messages.join(", ") }, status: :unprocessable_entity
                end
            end

            private 

            def set_board
                @board = Board.find(params[:id])
            rescue ActiveRecord::RecordNotFound
                render json: { status: 'error', message: 'ボードが見つかりません。' }, status: :not_found
            end

            def board_params
                params.require(:board).permit(:name, :active_player)
            end
        end
    end
end