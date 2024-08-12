require_relative "pieces"
require "byebug"

module Shogi 
    class Board 
        def initialize
            #初期配置を作成
            @initial_board = initial_board
        end

        def initial_board
        [
        ["KY", "KE", "GI", "KI", "OU", "KI", "GI", "KE", "KY"], # P1
        [nil, "HI", nil, nil, nil, nil, nil, "KA", nil],        # P2
        ["FU", "FU", "FU", "FU", "FU", "FU", "FU", "FU", "FU"], # P3
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],          # P4
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],          # P5
        [nil, nil, nil, nil, nil, nil, nil, nil, nil],          # P6
        ["+FU", "+FU", "+FU", "+FU", "+FU", "+FU", "+FU", "+FU", "+FU"], # P7
        [nil, "+KA", nil, nil, nil, nil, nil, "+HI", nil],      # P8
        ["+KY", "+KE", "+GI", "+KI", "+OU", "+KI", "+GI", "+KE", "+KY"]  # P9
        ]
        end

        def move(board,previous_position,next_position,piece)
            if(board[previous_position[0]][previous_position[1]] == piece ) 
                board[previous_position[0]][previous_position[1]] = nil
                board[next_position[0]][next_position[1]] = piece
            end
        end

        def display 
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end
    end
end
