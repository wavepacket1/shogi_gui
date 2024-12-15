
module Api
    module V1
        class PiecesController < ApplicationController
            def update
                piece = Piece.find(params[:id])
                if piece.update(piece_params)
                    render json: { status: 'success', piece: piece }, status: :ok
                else
                    render json: { status: 'error', message: piece.errors.full_messages.join(", ") }, status: :unprocessable_entity
                end
            end

            private

            def piece_params
                params.require(:piece).permit(:position_x, :position_y)
            end
        end
    end
end