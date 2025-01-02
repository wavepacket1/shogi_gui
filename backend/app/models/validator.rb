class Validator
    class << self
        def validate!(game, board, move_str)
            parsed_data = Board.parse_board_data(board)
            move_info = Board.parse_move(move_str)
    
            validate_move!(parsed_data, move_info)
            Board.create_next_board(parsed_data, move_info, board, game)
        end
    
        def  valid_move_or_drop?(board_array, hand, side, move_info)
            case move_info[:type]
            when :move
                valid_move?(board_array, hand, side, move_info)
            when :drop
                valid_drop?(board_array, hand, side, move_info)
            else 
                raise ArgumentError, "Invalid move type: #{move_info[:type]}"
            end
        end
    
        def valid_move?(board_array, hand, side, move_info)
            from_piece = board_array[move_info[:from_row]][move_info[:from_col]]
            to_piece = board_array[move_info[:to_row]][move_info[:to_col]]

            # 駒の捕獲
            capture_piece!(to_piece, hand, side) if to_piece

            # 移動元の駒を消去
            clear_source_square!(board_array, move_info)
            
            # 移動先に駒を配置
            place_piece!(board_array, from_piece, move_info)

            true
        end
        
        def valid_drop?(board_array, hand, side, move_info)
            piece_key = determine_piece_key(move_info[:piece], side)

            # 持ち駒を確認
            validate_hand!(hand, piece_key)

            # 持ち駒を減らす
            decrease_hand_piece!(hand, piece_key)

            # 盤面に駒を配置
            place_piece_on_board!(board_array, move_info[:to_row], move_info[:to_col], piece_key)

            true
        rescue StandardError => e
            render_error_response(e.message)
        end
    
        def legal_move?(board_array, side, move_info)
            case move_info[:type]
            when :move then legal_piece_move?(board_array, side, move_info)
            when :drop then legal_drop?(board_array, side, move_info)
            else false
            end
        end

        def legal_piece_move?(board_array, side, move_info)
            from_piece = fetch_piece(board_array, move_info[:from_row], move_info[:from_col])
            return false unless valid_from_piece?(from_piece, side)

            to_piece = fetch_piece(board_array, move_info[:to_row], move_info[:to_col])
            return false unless valid_to_piece?(to_piece, side)
    
            validate_piece_movement?(from_piece, board_array, side, move_info)
        end

        def legal_drop?(board_array, side, move_info)
            piece_type = move_info[:piece].upcase
            to_row = move_info[:to_row]
            to_col = move_info[:to_col]

            return false unless drop_target_empty?(board_array, to_row, to_col)
            return false if piece_type == 'P' && validate_no_pawn_in_column?(board_array, to_col, side)
            return false if drop_restriction_violation?(piece_type, to_row, side)

            true
        end
    
        def validate_move!(parsed_data, move_info)
            unless legal_move?(
                parsed_data[:board_array], 
                parsed_data[:side], 
                move_info
                )
                raise StandardError, '不正な手です。'
            end
        end

        private 
        # 移動先に駒がないことを確認
        def drop_target_empty?(board_array, row, col)
            board_array[row][col].nil?
        end
        
        # 二歩のチェック
        def validate_no_pawn_in_column?(board_array, col, side)
            column = board_array.map { |row| row[col] }
            column.any? do |cell|
                next false unless cell
                cell_type = cell.upcase
                cell_owner = cell.upcase == cell ? 'b' : 'w'
                cell_type == 'P' && cell_owner == side
            end
        end
        
        # 最奥段への打ち駒制限
        def drop_restriction_violation?(piece_type, to_row, side)
            case piece_type
            when 'P', 'L'
            (side == 'b' && to_row == 0) || (side == 'w' && to_row == 8)
            when 'N'
            (side == 'b' && to_row <= 1) || (side == 'w' && to_row >= 7)
            else
            false
            end
        end

        def fetch_piece(board_array, row, col)
            board_array[row][col]
        end
        
        def valid_from_piece?(from_piece, side)
            return false if from_piece.nil?

            is_black_piece = from_piece.upcase == from_piece
            side == 'b' ? is_black_piece : !is_black_piece
        end
        
        def valid_to_piece?(to_piece, side)
            return true if to_piece.nil?

            is_to_black_piece = to_piece.upcase == to_piece
            side == 'b' ? !is_to_black_piece : is_to_black_piece
        end

        def determine_piece_key(piece, side)
            side == 'b' ? piece.upcase : piece.downcase
        end

        def promote_piece(piece)
            "+#{piece}"
        end

        def validate_hand!(hand, piece_key)
            unless hand[piece_key]&.positive?
                raise StandardError, "持ち駒（#{piece_key}）がありません"
            end
        end

        def decrease_hand_piece!(hand, piece_key)
            hand[piece_key] -= 1
            hand.delete(piece_key) if hand[piece_key].zero?
        end

        def place_piece_on_board!(board_array, row, col, piece_key)
            board_array[row][col] = piece_key
        end
        
        def render_error_response(message)
            render json: {
                status: 'error',
                message: message
            }, status: :unprocessable_entity
        end

        def capture_piece!(to_piece, hand, side)
            captured_piece = to_piece.gsub(/^\+/, '') # 成り駒を基本形に戻す
            captured_piece = side == 'b' ? captured_piece.upcase : captured_piece.downcase # 駒を手駒として変換
            hand[captured_piece] ||= 0
            hand[captured_piece] += 1
        end

        def clear_source_square!(board_array, move_info)
            board_array[move_info[:from_row]][move_info[:from_col]] = nil
        end
    
        def place_piece!(board_array, from_piece, move_info)
            piece = move_info[:promoted] ? promote_piece(from_piece) : from_piece
            board_array[move_info[:to_row]][move_info[:to_col]] = piece
        end

        def validate_piece_movement?(from_piece, board_array, side, move_info)
            piece_type = from_piece.upcase
            piece_class = get_piece_class(piece_type)

            piece_type.start_with?('+') ? piece_class.promoted_move?(move_info, board_array, side) : piece_class.move?(move_info, board_array, side)
        end

        def get_piece_class(piece_type)
            normalized_type = piece_type.gsub('+', '')

            "Pieces::#{normalized_type}".constantize
        end
    end
end