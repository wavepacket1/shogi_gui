class Validator
    class << self
        # 合法手かどうかを判定する
        def legal?(parsed_data, move_info)
            board_array = parsed_data[:board_array]
            side = parsed_data[:side]

            return false unless basic_legal_move?(board_array, side, move_info)
            
            # 王手放置のチェック
            simulated_board = simulate_move(board_array, move_info)
            !in_check?(simulated_board, side)
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

        def simulate_move(board_array, move_info)
            new_board = board_array.deep_dup
            
            case move_info[:type]
            when :move
                new_board[move_info[:to_row]][move_info[:to_col]] = 
                    move_info[:promoted] ? 
                    "+#{new_board[move_info[:from_row]][move_info[:from_col]]}" : 
                    new_board[move_info[:from_row]][move_info[:from_col]]
                new_board[move_info[:from_row]][move_info[:from_col]] = nil
            when :drop
                piece = move_info[:piece]
                new_board[move_info[:to_row]][move_info[:to_col]] = piece
            end
            
            new_board
        end

        def in_check?(board_array, side)
            king_pos = find_king(board_array, side)
            return true unless king_pos # 王がない場合は王手とみなす
    
            opponent_side = side == 'b' ? 'w' : 'b'
            
            board_array.each_with_index do |row, from_row|
                row.each_with_index do |piece, from_col|
                    next if piece.nil?
                    next if piece_owner(piece) != opponent_side
        
                    move_info = {
                        type: :move,
                        from_row: from_row,
                        from_col: from_col,
                        to_row: king_pos[0],
                        to_col: king_pos[1]
                    }
        
                    piece_type = piece.gsub(/^\+/, '').upcase
                    piece_class = Piece.get_piece_class(piece_type)
                    
                    if piece.start_with?('+')
                        return true if piece_class.promoted_move?(move_info, board_array, opponent_side)
                    else
                        return true if piece_class.move?(move_info, board_array, opponent_side)
                    end
                end
            end
            false
        end

        def basic_legal_move?(board_array, side, move_info)
            case move_info[:type]
            when :move then legal_move?(board_array, side, move_info)
            when :drop then legal_drop?(board_array, side, move_info)
            else false
            end
        end

        def find_king(board_array, side)
            king_symbol = side == 'b' ? 'K' : 'k'
            board_array.each_with_index do |row, i|
                row.each_with_index do |piece, j|
                    return [i, j] if piece == king_symbol
                end
            end
            nil
        end
    
        def piece_owner(piece)
            piece.upcase == piece ? 'b' : 'w'
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
    end
end