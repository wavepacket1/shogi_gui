class Validator
    class << self
        # 合法手かどうかを判定する
        def legal?(parsed_data, move_info)
            board_array = parsed_data[:board_array]
            side = parsed_data[:side]

            case move_info[:type]
            when :move then legal_move?(board_array, side, move_info)
            when :drop then legal_drop?(board_array, side, move_info)
            else false
            end
        end

        def legal_move?(board_array, side, move_info)
            from_piece = Piece.fetch_piece(board_array, move_info[:from_row], move_info[:from_col])
            return false unless Piece.valid_from_piece?(from_piece, side)

            to_piece = Piece.fetch_piece(board_array, move_info[:to_row], move_info[:to_col])
            return false unless Piece.valid_to_piece?(to_piece, side)
    
            piece_type = from_piece.upcase
            piece_class = Piece.get_piece_class(piece_type)

            piece_type.start_with?('+') ? piece_class.promoted_move?(move_info, board_array, side) : piece_class.move?(move_info, board_array, side)
        end

        def legal_drop?(board_array, side, move_info)
            piece_type = move_info[:piece].upcase
            to_row = move_info[:to_row]
            to_col = move_info[:to_col]

            return false unless Piece.drop_target_empty?(board_array, to_row, to_col)
            return false if piece_type == 'P' && validate_no_pawn_in_column?(board_array, to_col, side)
            return false if drop_restriction_violation?(piece_type, to_row, side)

            true
        end

        private 

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
    end
end