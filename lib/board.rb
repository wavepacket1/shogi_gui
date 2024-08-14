require_relative "pieces"
require "byebug"

module Shogi 
    class Board 
        attr_reader :board
        def initialize
            #初期配置を作成
            @board = initial_board
            #先手番ならtrue,後手番ならfalse
            @turn = true
        end

        def initial_board
        [
            ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
            [nil, "r", nil, nil, nil, nil, nil, "b", nil],        # P2
            ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],          # P4
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],          # P5
            [nil, nil, nil, nil, nil, nil, nil, nil, nil],          # P6
            ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
            [nil, "B", nil, nil, nil, nil, nil, "R", nil],      # P8
            ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
            [],#先手の持ち駒
            [],#後手の持ち駒
        ]
        end
        
        def take_piece(present_position,next_position,turn,piece)
            return if !@board[next_position[0]][next_position[1]]
            #取った駒を持ち駒に追加
            if(turn == -1)
                @board[9].push(piece)
            else
                @board[10].push(piece)
            end
        end

        def take_piece_validation(next_position,turn)

        end

        def move(move_protocol)
            #先手番を２回続けて動かすことはできない
            if move_protocol[-1] =~ /[A-Z]/ && !@turn
                raise "先手番を２回続けて動かすことはできません"
            elsif move_protocol[-1] =~ /[a-z]/ && @turn
                raise "後手番を２回続けて動かすことはできません"
            end
            move_direction =if @turn 
                                -1
                            else
                                1
                            end
            @turn = !@turn 
            present_position = [move_protocol[1].to_i-1,9-move_protocol[0].to_i]
            next_position = [move_protocol[3].to_i-1,9-move_protocol[2].to_i]
            piece = (move_protocol[-1]).to_s

            if(@board[present_position[0]][present_position[1]] == piece && piece_validation(@board,piece,present_position,next_position,move_direction))
                #動いた先に駒があった時に持ち駒に追加するようにする
                take_piece(present_position,next_position,move_direction,piece)
                @board[present_position[0]][present_position[1]] = nil
                @board[next_position[0]][next_position[1]] = piece
            end
        end

        def display 
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end

        ##次の位置まで駒が動けるかをvalidationする
        def piece_validation(board,piece,present_position,next_position,move_direction)
            if piece == "p" || piece == "P"
                Shogi::Pieces::P.p_validation(board,present_position,next_position,move_direction)
            elsif piece == "n" || piece == "N" 
                Shogi::Pieces::N.n_validation(board,present_position,next_position,move_direction)
            elsif piece == "k" || piece == "K"
                Shogi::Pieces::K.k_validation(board,present_position,next_position,move_direction)
            elsif piece == "b" || piece == "B"
                Shogi::Pieces::B.b_validation(board,present_position,next_position,move_direction)
            elsif piece == "l" || piece == "L"
                Shogi::Pieces::L.l_validation(board,present_position,next_position,move_direction)
            elsif piece == "s" || piece == "S"
                Shogi::Pieces::S.s_validation(board,present_position,next_position,move_direction)
            elsif piece == "g" || piece == "G"
                Shogi::Pieces::G.g_validation(board,present_position,next_position,move_direction)
            elsif piece == "r" || piece == "R"
                Shogi::Pieces::R.r_validation(board,present_position,next_position,move_direction)
            end
        end

    end
end
