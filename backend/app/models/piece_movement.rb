
class PieceMovement
    class << self
        # def pawn_move?(move_info, side, piece)
        #     dx = move_info[:to_col] - move_info[:from_col]
        #     dy = move_info[:to_row] - move_info[:from_row]
            
        #     if piece.start_with?('+')  # 成り駒は金と同じ動き
        #         return gold_move?(move_info, side)
        #     end
            
        #     # 歩は1マス前にのみ進める
        #     dx == 0 && ((side == 'b' && dy == -1) || (side == 'w' && dy == 1))
        # end
        
        # def lance_move?(move_info, side, board_array)
        #     dx = move_info[:to_col] - move_info[:from_col]
        #     dy = move_info[:to_row] - move_info[:from_row]
            
        #     return false unless dx == 0
        #     direction = side == 'b' ? -1 : 1
        #     return false unless dy * direction > 0
            
        #     # 途中に駒がないか確認
        #     from_row = move_info[:from_row]
        #     to_row = move_info[:to_row]
        #     col = move_info[:from_col]
            
        #     range = from_row < to_row ? (from_row + 1...to_row) : (to_row + 1...from_row)
        #     range.none? { |row| board_array[row][col] }
        # end
        
        # def knight_move?(move_info, side)
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = move_info[:to_row] - move_info[:from_row]
            
        #     dx == 1 && ((side == 'b' && dy == -2) || (side == 'w' && dy == 2))
        # end
        
        # def silver_move?(move_info, side, piece)
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = move_info[:to_row] - move_info[:from_row]
            
        #     if piece.start_with?('+')  # 成り駒は金と同じ動き
        #         return gold_move?(move_info, side)
        #     end
            
        #     # 前方と斜め
        #     (dx == 0 && ((side == 'b' && dy == -1) || (side == 'w' && dy == 1))) ||
        #     (dx == 1 && (dy == 1 || dy == -1))
        # end
        
        # def gold_move?(move_info, side)
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = move_info[:to_row] - move_info[:from_row]
            
        #     if side == 'b'
        #         (dx == 0 && dy == -1) ||  # 前
        #         (dx == 1 && dy == -1) ||  # 斜め前
        #         (dx == 1 && dy == 0) ||   # 横
        #         (dx == 0 && dy == 1)      # 後ろ
        #     else
        #         (dx == 0 && dy == 1) ||   # 前
        #         (dx == 1 && dy == 1) ||   # 斜め前
        #         (dx == 1 && dy == 0) ||   # 横
        #         (dx == 0 && dy == -1)     # 後ろ
        #     end
        # end
        
        # def bishop_move?(move_info, board_array)
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = (move_info[:to_row] - move_info[:from_row]).abs
            
        #     return false unless dx == dy
            
        #     # 途中に駒がないか確認
        #     x_direction = move_info[:to_col] > move_info[:from_col] ? 1 : -1
        #     y_direction = move_info[:to_row] > move_info[:from_row] ? 1 : -1
            
        #     current_x = move_info[:from_col] + x_direction
        #     current_y = move_info[:from_row] + y_direction
            
        #     while current_x != move_info[:to_col]
        #         return false if board_array[current_y][current_x]
        #         current_x += x_direction
        #         current_y += y_direction
        #     end
            
        #     true
        # end
        
        # def rook_move?(move_info, board_array)
        #     dx = move_info[:to_col] - move_info[:from_col]
        #     dy = move_info[:to_row] - move_info[:from_row]
            
        #     return false unless dx == 0 || dy == 0
            
        #     if dx == 0
        #         range = dy > 0 ? (move_info[:from_row] + 1...move_info[:to_row]) : (move_info[:to_row] + 1...move_info[:from_row])
        #         range.none? { |row| board_array[row][move_info[:from_col]] }
        #     else
        #         range = dx > 0 ? (move_info[:from_col] + 1...move_info[:to_col]) : (move_info[:to_col] + 1...move_info[:from_col])
        #         range.none? { |col| board_array[move_info[:from_row]][col] }
        #     end
        # end
        
        # def king_move?(move_info)
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = (move_info[:to_row] - move_info[:from_row]).abs
            
        #     dx <= 1 && dy <= 1
        # end
        
        # def promoted_bishop_move?(move_info, board_array)
        #     # 角の動き
        #     return true if bishop_move?(move_info, board_array)
        
        #     # 玉の動き（隣接1マス）
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = (move_info[:to_row] - move_info[:from_row]).abs
        #     dx <= 1 && dy <= 1
        # end
        
        # def promoted_rook_move?(move_info, board_array)
        #     return true if rook_move?(move_info, board_array)
        
        #     # 玉の動き（隣接1マス）
        #     dx = (move_info[:to_col] - move_info[:from_col]).abs
        #     dy = (move_info[:to_row] - move_info[:from_row]).abs
        #     dx <= 1 && dy <= 1
        # end
    end
end
