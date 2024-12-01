# frozen_string_literal: true

module Api
  module V1
    class GamesController < ApplicationController
      def create
        @game = Game.new(game_params)
        if @game.save
          @board = @game.create_board(name: "Game #{@game.id}", step_number: Game.where(id: @game.id).count - 1)
          render json: { status: 'success', game: @game, board: @board }, status: :created
        else
          render json: { status: 'error', message: @game.errors.full_messages.join(', ') },
                status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { status: 'error', message: e.message }, status: :unprocessable_entity
      end

      def show
        @game = Game.find(params[:id])
        render json: @game, include: :board
      rescue ActiveRecord::RecordNotFound
        render json: { status: 'error', message: 'ゲームが見つかりません。' }, status: :not_found
      end

      private

      def game_params
        params.require(:game).permit(:name, :status)
      end
    end
  end
end
