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
            [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
            ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
            [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
            [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
            [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
            ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
            [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
            ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
            ["P"],#先手の持ち駒
            ["p"],#後手の持ち駒
        ]
        end
        
        def take_piece(present_position,next_position,turn,piece)
            return if !@board[next_position[0]][next_position[1]]
            if (turn && (@board[next_position[0]][next_position[1]]=~ /[A-Z]/) ) || (!turn && (@board[next_position[0]][next_position[1]]=~ /[a-z]/))
                raise "移動先に自分の駒があります"
            end
            #取った駒を持ち駒に追加
            if(turn)
                @board[9].push(@board[next_position[0]][next_position[1]].upcase)
            else
                @board[10].push(@board[next_position[0]][next_position[1]].downcase)
            end
        end

        #持ち駒の駒を打つ時
        def strike_piece(move_protocol,move_direction)
            next_position = [move_protocol[3].to_i-1,9-move_protocol[2].to_i]
            piece = (move_protocol[-1]).to_s
            return if(!strike_piece_validation(piece,next_position,move_direction))
            @board[next_position[0]][next_position[1]] = piece
            #先手の持ち駒の時
            if move_protocol[0..1]=="H0"
                @board[9].delete_at(@board[9].index(piece))
            #後手の持ち駒の時
            elsif move_protocol[0..1]=="H1"
                @board[10].delete_at(@board[10].index(piece))
            end
        end
        def strike_piece_validation(piece,next_position,move_direction)
            #持ち駒がそもそも存在するかどうかを確認
            if @turn
                if(!@board[9].include?(piece))
                    raise "持ち駒が存在しません"
                end
            else
                if(!@board[10].include?(piece))
                    raise "持ち駒が存在しません"
                end
            end
            #打つ場所に駒がないかどうかを確認
            if(@board[next_position[0]][next_position[1]])
                raise "打つ場所に駒があります"
            end
            #駒が動けない場所かどうかを確認
            if(!can_move_validation(@board,next_position,move_direction,piece))
                raise "その場所に駒は打てません"
            end
            #二歩のチェック

            true
        end

        def can_move_validation(board,next_position,move_direction,piece)
            if piece == "p" || piece == "P"
                Shogi::Pieces::P.p_can_move_validation(board,next_position,move_direction)
            elsif piece == "n" || piece == "N" 
                Shogi::Pieces::N.n_can_move_validation(board,next_position,move_direction)
            elsif piece == "k" || piece == "K"
                Shogi::Pieces::K.k_can_move_validation(board,next_position,move_direction)
            elsif piece == "b" || piece == "B"
                Shogi::Pieces::B.b_can_move_validation(board,next_position,move_direction)
            elsif piece == "l" || piece == "L"
                Shogi::Pieces::L.l_can_move_validation(board,next_position,move_direction)
            elsif piece == "s" || piece == "S"
                Shogi::Pieces::S.s_can_move_validation(board,next_position,move_direction)
            elsif piece == "g" || piece == "G"
                Shogi::Pieces::G.g_can_move_validation(board,next_position,move_direction)
            elsif piece == "r" || piece == "R"
                Shogi::Pieces::R.r_can_move_validation(board,next_position,move_direction)
            end
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
            
            #駒を打つ時のロジック
            return strike_piece(move_protocol,move_direction) if move_protocol[0]=="H"


            present_position = [move_protocol[1].to_i-1,9-move_protocol[0].to_i]
            next_position = [move_protocol[3].to_i-1,9-move_protocol[2].to_i]
            piece = (move_protocol[-1]).to_s
                    

            if(@board[present_position[0]][present_position[1]] == piece && piece_validation(@board,piece,present_position,next_position,move_direction))
                #動いた先に駒があった時に持ち駒に追加するようにする
                take_piece(present_position,next_position,@turn,piece)
                @board[present_position[0]][present_position[1]] = nil
                @board[next_position[0]][next_position[1]] = piece
            end
            @turn = !@turn 
        end

        def display 
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end

        def reset
            @board = initial_board
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
