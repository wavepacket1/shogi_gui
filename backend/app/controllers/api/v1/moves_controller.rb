class Api::V1::MovesController < ApplicationController
  before_action :set_game_and_board
  def move
    move_str = params[:move]
    parsed_data = @board.parse_sfen

    board_array = parsed_data[:board_array]
    side = parsed_data[:side]
    hand = parsed_data
    move_number = parsed_data[:move_number]

    move_info = Board.parse_move(move_str, board_array, hand, side)

    unless legal_move?(board_array, hand, side, move_info)
      return render json: { status: 'error', message: '不正な手です。' }, status: :unprocessable_entity
    end

    case move_info[:type]
    when :move
      piece = board_array[move_info[:from_row]][move_info[:from_col]]
      board_array[move_info[:from_row]][move_info[:from_col]] = nil
      piece = promote_piece(piece) if move_info[:promoted]
      board_array[move_info[:to_row]][move_info[:to_col]] = piece
    when :drop
      piece = move_info[:piece]
      decrement_hand_piece(hand, piece, side)
      board_array[move_info[:to_row]][move_info[:to_col]] = piece
    end

    side = (side == 'b' ? 'w' : 'b')
    move_number += 1

    new_sfen = Board.array_to_sfen(board_array, side, hand, move_number)
    @next_board = Board.create!(game_id: @game.id, sfen: new_sfen)

    render jsom: { status: 'success', board: @next_board }, status: :ok
  end

  private 

  def set_game_and_board
    @game = Game.find(params[:game_id])
    @board = @game.boards.find(params[:board_id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'ゲームが見つかりません。' }, status: :not_found
  end
end
