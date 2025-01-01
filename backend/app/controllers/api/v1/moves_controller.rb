class Api::V1::MovesController < ApplicationController
  def move
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])
    move_str = params[:move]
    move_info = Board.parse_move(move_str)
    parsed_data = parse_board_data(@board)

    unless Move.legal_move?(parsed_data[:board_array], parsed_data[:hand], parsed_data[:side], move_info)
      return render json: { 
        status: 'error', 
        message: '不正な手です。'
      }, status: :unprocessable_entity
    end

    begin 
      next_board = Move.valid_move_or_drop?(
        parsed_data[:board_array], 
        parsed_data[:hand], 
        parsed_data[:side], 
        parsed_data[:move_number], 
        move_info,
        @board,
        @game
      )
      render json: {
        status: true,
        legal_flag: true,
        board_id: next_board.id,
        sfen: next_board.sfen
    }, status: :ok
    rescue StandardError => e
    render json: {
        status: false,
        message: e.message,
        board_id: board.id,
        sfen: board.sfen
    }, status: :unprocessable_entity
    end
  end

  private 
  def parse_board_data(board)
    parsed_data = board.parse_sfen
    {
      board_array: parsed_data[:board_array],
      side: parsed_data[:side],
      hand: parsed_data[:hand] || {},
      move_number: parsed_data[:move_number]
    }
  end
end
