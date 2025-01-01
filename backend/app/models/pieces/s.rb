module Pieces   
    class S 
        class << self 
            def move?(move_info, side, piece) 
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = move_info[:to_row] - move_info[:from_row]
                
                # 前方と斜め
                (dx == 0 && ((side == 'b' && dy == -1) || (side == 'w' && dy == 1))) ||
                (dx == 1 && (dy == 1 || dy == -1))
            end
        end
    end
end