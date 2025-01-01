module Pieces
    class N
        class << self
            def move?(move_info, side)
                dx = (move_info[:to_col] - move_info[:from_col]).abs
                dy = move_info[:to_row] - move_info[:from_row]
                
                dx == 1 && ((side == 'b' && dy == -2) || (side == 'w' && dy == 2))
            end
        end
    end
end