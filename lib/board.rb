require_relative "pieces"
require "byebug"

module Shogi 
    class Board 
        #駒と成駒の対応関係
        RELEASION_PIECE_AND_PROMOTION_PIECE = {
            "t"=>"p","T" => "P",
            "y"=>"l","Y" => "L",
            "e"=>"n","E" => "N",
            "i"=>"s","I" => "S",
            "z"=>"r","Z" => "R",
            "u"=>"b","U" => "B"
    }

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
            [],#先手の持ち駒
            [],#後手の持ち駒
        ]
        end
        
        def take_piece(present_position,next_position,turn,piece)
            return if !@board[next_position[0]][next_position[1]]
            if (turn && (@board[next_position[0]][next_position[1]]=~ /[A-Z]/) ) || (!turn && (@board[next_position[0]][next_position[1]]=~ /[a-z]/))
                raise "移動先に自分の駒があります"
            end
            #取った駒を持ち駒に追加
            if(turn)
                #取る駒が成駒の時
                if(promotion_piece?(@board[next_position[0]][next_position[1]]))
                    @board[9].push(RELEASION_PIECE_AND_PROMOTION_PIECE[@board[next_position[0]][next_position[1]]].upcase)
                else
                    @board[9].push(@board[next_position[0]][next_position[1]].upcase)
                end
            else
                if(promotion_piece?(@board[next_position[0]][next_position[1]]))
                    @board[10].push(RELEASION_PIECE_AND_PROMOTION_PIECE[@board[next_position[0]][next_position[1]]].downcase)
                else
                    @board[10].push(@board[next_position[0]][next_position[1]].downcase)
                end
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
            if((piece == "P" || piece == "p") && !validation_two_pawn(next_position))
                raise "二歩です"
            end
            true
        end

        def validation_two_pawn(next_position)
            pawn_position=next_position[1]
            (0..8).each do |i|
                next if i == next_position[0]
                if @turn 
                    return false if board[i][pawn_position] == "P"
                else
                    return false if board[i][pawn_position] == "P"
                end
            end
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
            elsif piece == "T" || piece == "t"
                Shogi::Pieces::T.t_can_move_validation(board,next_position,move_direction)
            elsif piece == "Y" || piece == "y"
                Shogi::Pieces::Y.y_can_move_validation(board,next_position,move_direction)
            elsif piece == "E" || piece == "e"
                Shogi::Pieces::E.e_can_move_validation(board,next_position,move_direction)
            elsif piece == "I" || piece == "i"
                Shogi::Pieces::I.i_can_move_validation(board,next_psition,move_direction)
            elsif piece == "Z" || piece == "z"
                Shogi::Pieces::Z.z_can_move_validation(board,next_position,move_direction)
            elsif piece == "U" || piece == "u"
                Shogi::Pieces::U.u_can_move_validation(board,next_position,move_direction)
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
            if  move_protocol.length == 6
                before_piece = move_protocol[-2]
                promote_piece = move_protocol[-1]
                if promotion_piece?(promote_piece)
                    raise "成れません" unless promotion_validation(next_position)
                end
                if(@board[present_position[0]][present_position[1]] == before_piece && piece_validation(@board,before_piece,present_position,next_position,move_direction))
                    #動いた先に駒があった時に持ち駒に追加するようにする
                    take_piece(present_position,next_position,@turn,before_piece)
                    @board[present_position[0]][present_position[1]] = nil
                    @board[next_position[0]][next_position[1]] = promote_piece
                end
            else
                piece = (move_protocol[-1]).to_s
                if(@board[present_position[0]][present_position[1]] == piece && piece_validation(@board,piece,present_position,next_position,move_direction))
                    #動いた先に駒があった時に持ち駒に追加するようにする
                    take_piece(present_position,next_position,@turn,piece)
                    @board[present_position[0]][present_position[1]] = nil
                    @board[next_position[0]][next_position[1]] = piece
                end
            end
            @turn = !@turn 
        end

        def promotion_piece?(piece)
            (piece == "T" || piece == "t") || (piece == "Y" || piece == "y") || (piece == "E" || piece == "e") || (piece == "I" || piece == "i") || (piece == "Z" || piece == "z") || (piece == "U" || piece == "u")
        end

        def display 
            @board.each do |row|
                puts row.map { |cell| cell.nil? ? "*" : cell }.join(" ")
            end
        end

        def reset
            @board = initial_board
        end

        #成れるかどうかをチェックする
        def promotion_validation(next_position)
            if(@turn)
                if next_position[0]<=2
                    true
                else
                    false
                end
            else
                if next_position[0]>=6
                    true
                else
                    false
                end
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
            elsif piece == "T" || piece == "t"
                Shogi::Pieces::T.t_validation(board,present_position,next_position,move_direction)
            elsif piece == "Y" || piece == "y"
                Shogi::Pieces::Y.y_validation(board,present_position,next_position,move_direction)
            elsif piece == "E" || piece == "e"
                Shogi::Pieces::E.e_validation(board,present_position,next_position,move_direction)
            elsif piece == "I" || piece == "i"
                Shogi::Pieces::I.i_validation(board,present_position,next_position,move_direction)
            elsif piece == "Z" || piece == "z"
                Shogi::Pieces::Z.z_validation(board,present_position,next_position,move_direction)
            elsif piece == "U" || piece == "u"
                Shogi::Pieces::U.u_validation(board,present_position,next_position,move_direction)
            end
        end
    end
end
