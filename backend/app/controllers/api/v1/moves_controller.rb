class Api::V1::MovesController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def move
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])
    parsed_data = Parser::SfenParser.parse(@board.sfen)  
    move_info = Board.parse_move(params[:move])

    # 合法手でない場合はDBに保存しない
    return unless Validator.legal?(parsed_data, move_info, @game)

    next_board = Move.process_move(@game, @board, parsed_data, move_info)
    render_success(next_board, @game)
  rescue StandardError => e
    render_error(e)
  end

  private

  def render_success(next_board, game)
    next_board_array = Parser::SfenParser.parse(next_board.sfen)[:board_array]
    next_side = Parser::SfenParser.parse(next_board.sfen)[:side]

    render json: {
      status: true,
      is_checkmate: Validator.is_checkmate?(next_board.sfen),
      is_repetition: Validator.repetition?(next_board.sfen, game),
      is_repetition_check: Validator.repetition_check?(next_board_array, next_side, game),
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
