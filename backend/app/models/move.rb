class Move < ApplicationRecord
    belongs_to :board
    belongs_to :piece, optional: true

    def to_sfen_move
        promotion_flag = promotion ? '+' : ''
        "+{from_x}#{from_y}#{promotion_flag}#{to_x}#{to_y}"
    end

    class << self
        def process_move(game, board, move_str)
            move_info = Board.parse_move(move_str)
            parsed_data = Board.parse_board_data(board)

            validate_move!(parsed_data, move_info)
            create_next_board(parsed_data, move_info, board, game)
        end

        def legal_move?(board_array, hand, side, move_info)
            case move_info[:type]
            when :move
                # 移動元に駒があるか確認
                from_piece = board_array[move_info[:from_row]][move_info[:from_col]]
                return false unless from_piece
        
                # 自分の駒かどうか確認
                is_black_piece = from_piece.upcase == from_piece
                return false if (side == 'b' && !is_black_piece) || (side == 'w' && is_black_piece)
            
                # 移動先の駒が自分の駒でないことを確認
                to_piece = board_array[move_info[:to_row]][move_info[:to_col]]
                if to_piece
                    is_to_black_piece = to_piece.upcase == to_piece
                    return false if (side == 'b' && is_to_black_piece) || (side == 'w' && !is_to_black_piece)
                end
        
                # 駒の種類に応じた移動可能範囲の確認
                piece_type = from_piece.gsub(/^\+/, '').upcase
                can_move = case piece_type
                when 'P'  # 歩
                    pawn_move?(move_info, side, from_piece)
                when 'L'  # 香車
                    lance_move?(move_info, side, board_array)
                when 'N'  # 桂馬
                    knight_move?(move_info, side)
                when 'S'  # 銀
                    silver_move?(move_info, side, from_piece)
                when 'G', '+P', '+L', '+N', '+S'  # 金、成り駒
                    gold_move?(move_info, side)
                when 'B'  # 角
                    from_piece.start_with?('+') ? promoted_bishop_move?(move_info, board_array) : bishop_move?(move_info, board_array)
                when 'R'  # 飛車
                    from_piece.start_with?('+') ? promoted_rook_move?(move_info, board_array) : rook_move?(move_info, board_array)
                when 'K'  # 玉
                    king_move?(move_info)
                end
        
                return can_move
        
            when :drop
                piece_type = move_info[:piece].upcase
                to_row = move_info[:to_row]
            
                # 移動先に駒がないことを確認
                return false if board_array[move_info[:to_row]][move_info[:to_col]]
            
                # 二歩のチェック
                if piece_type == 'P'
                    column = board_array.map { |row| row[move_info[:to_col]] }
                    has_pawn = column.any? do |cell|
                    next false unless cell
                    cell_type = cell.gsub(/^\+/, '').upcase
                    cell_owner = cell.upcase == cell ? 'b' : 'w'
                    cell_type == 'P' && cell_owner == side
                    end
                    return false if has_pawn
                end
            
                # 最奥段への打ち駒制限
                case piece_type
                when 'P', 'L'
                    return false if (side == 'b' && to_row == 0) || (side == 'w' && to_row == 8)
                when 'N'
                    return false if (side == 'b' && to_row <= 1) || (side == 'w' && to_row >= 7)
                end
            
                true
            end
        end

        def  valid_move_or_drop?(board_array, hand, side, move_number, move_info, board, game)
            begin
                case move_info[:type]
                when :move
                    valid_move?(board_array, hand, side, move_info)
                when :drop
                    valid_drop?(board_array, hand, side, move_info)
                else 
                    raise ArgumentError, "Invalid move type: #{move_info[:type]}"
                end
            
                side = (side == 'b' ? 'w' : 'b')
                move_number += 1
            
                new_sfen = Board.array_to_sfen(board_array, side, hand, move_number)
                next_board = Board.create!(game_id: game.id, sfen: new_sfen)
            end
        end

        private 

        def validate_move!(parsed_data, move_info)
            unless legal_move?(
                parsed_data[:board_array], 
                parsed_data[:hand], 
                parsed_data[:side], 
                move_info
                )
                raise StandardError, '不正な手です。'
            end
        end
        
        def create_next_board(parsed_data, move_info, board, game)
        valid_move_or_drop?(
            parsed_data[:board_array],
            parsed_data[:hand],
            parsed_data[:side],
            parsed_data[:move_number],
            move_info,
            board,
            game
        )
        end

        def valid_move?(board_array, hand, side, move_info)
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
            return true
        end
        
        def valid_drop?(board_array, hand, side, move_info)
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
            return true
        end

        def promote_piece(piece)
            "+#{piece}"
        end
        
        def pawn_move?(move_info, side, piece)
            dx = move_info[:to_col] - move_info[:from_col]
            dy = move_info[:to_row] - move_info[:from_row]
            
            if piece.start_with?('+')  # 成り駒は金と同じ動き
                return gold_move?(move_info, side)
            end
            
            # 歩は1マス前にのみ進める
            dx == 0 && ((side == 'b' && dy == -1) || (side == 'w' && dy == 1))
        end
        
        def lance_move?(move_info, side, board_array)
            dx = move_info[:to_col] - move_info[:from_col]
            dy = move_info[:to_row] - move_info[:from_row]
            
            return false unless dx == 0
            direction = side == 'b' ? -1 : 1
            return false unless dy * direction > 0
            
            # 途中に駒がないか確認
            from_row = move_info[:from_row]
            to_row = move_info[:to_row]
            col = move_info[:from_col]
            
            range = from_row < to_row ? (from_row + 1...to_row) : (to_row + 1...from_row)
            range.none? { |row| board_array[row][col] }
        end
        
        def knight_move?(move_info, side)
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = move_info[:to_row] - move_info[:from_row]
            
            dx == 1 && ((side == 'b' && dy == -2) || (side == 'w' && dy == 2))
        end
        
        def silver_move?(move_info, side, piece)
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = move_info[:to_row] - move_info[:from_row]
            
            if piece.start_with?('+')  # 成り駒は金と同じ動き
                return gold_move?(move_info, side)
            end
            
            # 前方と斜め
            (dx == 0 && ((side == 'b' && dy == -1) || (side == 'w' && dy == 1))) ||
            (dx == 1 && (dy == 1 || dy == -1))
        end
        
        def gold_move?(move_info, side)
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = move_info[:to_row] - move_info[:from_row]
            
            if side == 'b'
                (dx == 0 && dy == -1) ||  # 前
                (dx == 1 && dy == -1) ||  # 斜め前
                (dx == 1 && dy == 0) ||   # 横
                (dx == 0 && dy == 1)      # 後ろ
            else
                (dx == 0 && dy == 1) ||   # 前
                (dx == 1 && dy == 1) ||   # 斜め前
                (dx == 1 && dy == 0) ||   # 横
                (dx == 0 && dy == -1)     # 後ろ
            end
        end
        
        def bishop_move?(move_info, board_array)
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = (move_info[:to_row] - move_info[:from_row]).abs
            
            return false unless dx == dy
            
            # 途中に駒がないか確認
            x_direction = move_info[:to_col] > move_info[:from_col] ? 1 : -1
            y_direction = move_info[:to_row] > move_info[:from_row] ? 1 : -1
            
            current_x = move_info[:from_col] + x_direction
            current_y = move_info[:from_row] + y_direction
            
            while current_x != move_info[:to_col]
                return false if board_array[current_y][current_x]
                current_x += x_direction
                current_y += y_direction
            end
            
            true
        end
        
        def rook_move?(move_info, board_array)
            dx = move_info[:to_col] - move_info[:from_col]
            dy = move_info[:to_row] - move_info[:from_row]
            
            return false unless dx == 0 || dy == 0
            
            if dx == 0
                range = dy > 0 ? (move_info[:from_row] + 1...move_info[:to_row]) : (move_info[:to_row] + 1...move_info[:from_row])
                range.none? { |row| board_array[row][move_info[:from_col]] }
            else
                range = dx > 0 ? (move_info[:from_col] + 1...move_info[:to_col]) : (move_info[:to_col] + 1...move_info[:from_col])
                range.none? { |col| board_array[move_info[:from_row]][col] }
            end
        end
        
        def king_move?(move_info)
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = (move_info[:to_row] - move_info[:from_row]).abs
            
            dx <= 1 && dy <= 1
        end
        
        def promoted_bishop_move?(move_info, board_array)
            # 角の動き
            return true if bishop_move?(move_info, board_array)
        
            # 玉の動き（隣接1マス）
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = (move_info[:to_row] - move_info[:from_row]).abs
            dx <= 1 && dy <= 1
        end
        
        def promoted_rook_move?(move_info, board_array)
            return true if rook_move?(move_info, board_array)
        
            # 玉の動き（隣接1マス）
            dx = (move_info[:to_col] - move_info[:from_col]).abs
            dy = (move_info[:to_row] - move_info[:from_row]).abs
            dx <= 1 && dy <= 1
        end
    end
end