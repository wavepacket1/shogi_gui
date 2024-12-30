# frozen_string_literal: true

module Api
  module V1
    class GamesController < ApplicationController
      def create
        @game = Game.new(game_params)

        @game.errors.add(:status, "can't be blank") if game_params[:status].blank?
        
        if @game.errors.empty? && @game.save
          @board = @game.create_board!
          render json: {
            game_id: @game.id,
            status: @game.status,
            board_id: @board.id
          }, status: :created
        else
          render json: {
            error: @game.errors.full_messages.join(', ')
          }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def show
        @game = Game.find(params[:id])
        render json: @game, include: :board
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'ゲームが見つかりません。' }, status: :not_found
      end

      private

      def game_params
        params.require(:game).permit(:status)
      end
    end
  end
end
