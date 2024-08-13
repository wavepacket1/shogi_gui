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
            ["+KY", "+KE", "+GI", "+KI", "+OU", "+KI", "+GI", "+KE", "+KY"], # P9
            [],#先手の持ち駒
            [],#後手の持ち駒
        ]
        end
        
        def take_piece(board,present_position,next_position,turn,piece)
            return if !board[next_position[0]][next_position[1]]
            #取った駒を持ち駒に追加
            if(turn == -1)
                board[9].push(piece)
            else
                board[10].push(piece)
            end
        end

        def move(board,present_position,next_position,piece,turn)
            if(board[present_position[0]][present_position[1]] == piece && piece_validation(board,piece,present_position,next_position,turn)) 
                #動いた先に駒があった時に持ち駒に追加するようにする
                take_piece(board,present_position,next_position,turn,piece)
                board[present_position[0]][present_position[1]] = nil
                board[next_position[0]][next_position[1]] = piece
            end
        end

        def display 
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end

        ##次の位置まで駒が動けるかをvalidationする
        def piece_validation(board,piece,present_position,next_position,turn)
            if piece == "+FU"
                Shogi::Pieces::FU.fu_validation(board,present_position,next_position,turn)
            elsif piece == "+KE"
                Shogi::Pieces::KE.ke_validation(board,present_position,next_position,turn)
            elsif piece == "+OU"
                Shogi::Pieces::OU.ou_validation(board,present_position,next_position,turn)
            elsif piece == "+KA"
                Shogi::Pieces::KA.ou_validation(board,present_position,next_position,turn)
            elsif piece == "+KY"
                Shogi::Pieces::KY.ou_validation(board,present_position,next_position,turn)
            elsif piece == "+GI"
                Shogi::Pieces::GI.ou_validation(board,present_position,next_position,turn)
            elsif piece == "+KI"
                Shogi::Pieces::Ki.ou_validation(board,present_position,next_position,turn)
            elsif piece == "+HI"
                Shogi::Pieces::HI.ou_validation(board,present_position,next_position,turn)
            end
        end

    end
end
