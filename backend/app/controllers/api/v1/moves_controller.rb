class Api::V1::MovesController < ApplicationController
  before_action :set_game_and_board
  def move
    move_str = params[:move]
    parsed_data = @board.parse_sfen

    board_array = parsed_data[:board_array]
    side = parsed_data[:side]
    hand = parsed_data[:hand] || {}
    move_number = parsed_data[:move_number]

    move_info = Board.parse_move(move_str)

    unless legal_move?(board_array, hand, side, move_info)
      return render json: { 
        status: 'error', 
        message: '不正な手です。'
      }, status: :unprocessable_entity
    end

    begin
      case move_info[:type]
      when :move
        from_piece = board_array[move_info[:from_row]][move_info[:from_col]]
        to_piece = board_array[move_info[:to_row]][move_info[:to_col]]
        
        # 移動先に相手の駒がある場合、手駒に加える
        if to_piece
          captured_piece = to_piece.gsub(/^\+/, '')  # 成り駒は基本形に戻す
          # 先手が取った場合は大文字、後手が取った場合は小文字で持ち駒に追加
          # 取った駒は必ず相手の駒なので、先手なら小文字を大文字に、後手なら大文字を小文字に変換
          captured_piece = if side == 'b'
            captured_piece.upcase   # 先手が取った場合は大文字に
          else
            captured_piece.downcase # 後手が取った場合は小文字に
          end
          
          hand[captured_piece] ||= 0
          hand[captured_piece] += 1
        end

        # 移動元の駒を消す
        board_array[move_info[:from_row]][move_info[:from_col]] = nil
        
        # 移動先に駒を置く（必要に応じて成り駒に）
        piece = from_piece
        piece = promote_piece(piece) if move_info[:promoted]
        board_array[move_info[:to_row]][move_info[:to_col]] = piece
      when :drop
        piece = move_info[:piece]
        # 打つ駒は手番側の持ち駒から選ぶ（先手は大文字、後手は小文字）
        piece_key = if side == 'b'
          piece.upcase   # 先手の場合は大文字の持ち駒を使用
        else
          piece.downcase # 後手の場合は小文字の持ち駒を使用
        end
        
        # 持ち駒の存在と数の確認
        unless hand[piece_key] && hand[piece_key] > 0
          return render json: {
            status: 'error',
            message: "持ち駒（#{piece_key}）がありません"
          }, status: :unprocessable_entity
        end

        # 持ち駒を減らす
        hand[piece_key] -= 1
        if hand[piece_key] <= 0
          hand.delete(piece_key)
        end

        # 盤面に駒を置く（手番側の駒として）
        board_array[move_info[:to_row]][move_info[:to_col]] = piece_key
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
    rescue StandardError => e
      render json: {
        status: false,
        message: e.message,
        board_id: @board.id,
        sfen: @board.sfen
      }, status: :unprocessable_entity
    end
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
