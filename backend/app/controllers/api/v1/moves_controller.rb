class Api::V1::MovesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def move
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])

    next_board = Move.process_move(@game, @board, params[:move])
    render_success(next_board, @game)
  rescue StandardError => e
    render_error(e)
  end

  private

  def render_success(next_board, game)
    render json: {
      status: true,
      legal_flag: true,
      is_checkmate: Validator.is_checkmate?(next_board.sfen),
      repetition_flag: Validator.repetition?(next_board.sfen, game),
      board_id: next_board.id,
      sfen: next_board.sfen
    }, status: :ok
  end

  def render_error(error)
    render json: {
      status: false,
      message: error.message,
      board_id: @board.id,
      sfen: @board.sfen
    }, status: :unprocessable_entity
  end

  def record_not_found
    render json: {
      status: false,
      message: 'ゲームまたは盤面が見つかりません。'
    }, status: :not_found
  end
end
