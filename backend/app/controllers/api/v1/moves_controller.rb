class Api::V1::MovesController < ApplicationController
  before_action :set_game_and_board
  def move
    move_str = params[:move]
    parsed_data = @board.parse_sfen

    board_array = parsed_data[:board_array]
    side = parsed_data[:side]
    hand = parsed_data[:hand]
    move_number = parsed_data[:move_number]

    move_info = Board.parse_move(move_str)

    unless legal_move?(board_array, hand, side, move_info)
      return render json: { status: 'error', message: '不正な手です。' }, status: :unprocessable_entity
    end

    case move_info[:type]
    when :move
      from_piece = board_array[move_info[:from_row]][move_info[:from_col]]
      to_piece = board_array[move_info[:to_row]][move_info[:to_col]]
      
      # 移動先に相手の駒がある場合、手駒に加える
      if to_piece
          captured_piece = to_piece.gsub(/^\+/, '')  # 成り駒は基本形に戻す
          # 手番が先手(b)なら大文字、後手(w)なら小文字で持ち駒に追加
          captured_piece = side == 'b' ? captured_piece.upcase : captured_piece.downcase
          hand[captured_piece] = (hand[captured_piece] || 0) + 1
      end

      # 移動元の駒を消す
      board_array[move_info[:from_row]][move_info[:from_col]] = nil
      
      # 移動先に駒を置く（必要に応じて成り駒に）
      piece = from_piece
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

    render json: {
      status: true,
      legal_flag: true,
      board_id: @next_board.id,
      sfen: @next_board.sfen
    }, status: :ok
  rescue => e
    render json: {
      status: false,
      legal_flag: false,
      board_id: @board.id,
      sfen: @board.sfen,
      message: e.message
    }, status: :unprocessable_entity
  end

  private 

  def promote_piece(piece)
    "+#{piece}"
  end

  def legal_move?(board_array, hand, side, move_info)
    true
  end

  def set_game_and_board
    @game = Game.find(params[:game_id])
    @board = Board.find(params[:board_id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: 'error', message: 'ゲームが見つかりません。' }, status: :not_found
  end
end
