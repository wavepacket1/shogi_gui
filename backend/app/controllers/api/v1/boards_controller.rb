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
                @board = Board.new
                if @board.save
                    render json: { status: 'success', board: @board }, status: :created
                else
                    render json: { status: 'error', message: @board.errors.full_messages.join(", ") }, status: :unprocessable_entity
                end
            end

            def default 
                render json: {
                    sfen: default_sfen,
                    legal_flag: true
                }
            end

            private 

            def default_sfen
                "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0"
            end

            def set_board
                @board = Board.find(params[:id])
            rescue ActiveRecord::RecordNotFound
                render json: { status: 'error', message: 'ボードが見つかりません。' }, status: :not_found
            end
        end
    end
end