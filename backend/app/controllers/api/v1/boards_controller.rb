module Api
    module V1
        class BoardsController < ApplicationController
            def show
                board = Board.includes(:pieces).find(params[:id])
                render json: board.to_sfen(include: :pieces)
            rescue ActiveRecord::RecordNotFound
                render json: { error: "Board not found" }, status: :not_found
            end
        end
    end
end