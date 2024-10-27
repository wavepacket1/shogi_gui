require 'yaml' 
require_relative 'board'
require_relative 'piece_factory'
require_relative 'usi'
require 'byebug'

# YAMLファイルの読み込み
CONFIG = YAML.load_file(File.join(__dir__,'config/constants.yml'))
#定数の定義
HAND_INDEX_FIRST = CONFIG['HAND_INDEX_FIRST']
HAND_INDEX_SECOND = CONFIG['HAND_INDEX_SECOND']

# 持ち駒キーと対応する手駒インデックスのマッピング
PLAYER_HAND_INDEX = CONFIG['PLAYER_HAND_INDEX']
RELEASION_PIECE_AND_PROMOTION_PIECE = CONFIG['RELEASION_PIECE_AND_PROMOTION_PIECE'].freeze
UPPERCASE_PIECE_REGEX = /[A-Z]/ # 先手の駒は大文字
LOWERCASE_PIECE_REGEX = /[a-z]/ # 後手の駒は小文字

#board.rbでしか使われないようにする
class Validation 
    class << self
        # 王手がかかっているかどうか判定するメソッド    
        def check_detection?(board, piece, move_direction)
            return false
        end

        def check_usi_protocol?(usi_protocol)
            return false unless usi_protocol.is_a?(String)
            if usi_protocol.include?("+")
                usi_protocol.match?(/^([1-9][a-i])(?!\1)[1-9][a-i]\+$/) 
            elsif usi_protocol.include?("*")
                usi_protocol.match?(/^[K|R|B|G|S|N|L|P]\*[1-9][a-i]$/)
            else
                usi_protocol.match?(/^([1-9][a-i])(?!\1)[1-9][a-i]$/)
            end
        end

        #駒を動かす際に合法手かどうかを判定するメソッド
        def move_legal?(board, before_coordinate, after_coordinate, piece, move_direction, turn)
            check_detection?(board, piece, move_direction)
            can_next_position?(board, before_coordinate, after_coordinate, piece, move_direction, turn)
        end

        # 駒を打つ手が合法手かどうかを判定するメソッド
        def strike_legal?(board, after_coordinate, piece, move_direction, turn)
            check_detection?(board, piece, move_direction)
            validate_hand_exists(board, piece, turn)
            validate_place_empty(after_coordinate, board)
            can_piece_move_place?(after_coordinate, move_direction, piece,board)
            validate_two_pawn(piece, after_coordinate, board, turn)
            true
        end

        def promotion_legal?(board, before_coordinate, after_coordinate, piece, move_direction, turn)
            check_detection?(board, piece, move_direction)
            promotion_piece?(piece)
            promotion_validate(after_coordinate, turn)
        end

        # 移動するマス目に駒が存在するかを判定するメソッド
        def can_next_position?(board, before_coordinate, after_coordinate, piece, move_direction, turn)
            piece_object = PieceFactory::create_piece(piece)
            movement = piece_object.movement_patterns
            validate_movement(board, before_coordinate, after_coordinate, move_direction, movement)
            next_position_your_piece?(board, after_coordinate, piece, turn)
        end

        # 移動するマス目に自分の駒が存在するかを判定するメソッド
        def next_position_your_piece?(board, after_coordinate, piece, turn)
            destination_piece = board[after_coordinate[0]][after_coordinate[1]]
            !own_piece?(destination_piece, turn)
        end

        def own_piece?(piece, turn)
            return false if piece.nil?
            if turn 
                piece.match?(UPPERCASE_PIECE_REGEX)
            else
                piece.match?(LOWERCASE_PIECE_REGEX)
            end
        end

        def validate_movement(board, present_position, next_position, move_direction, movement)
            movement.each do |move|
                return true if knight_move?(move) && knight_next_position_move?(present_position, next_position, move, move_direction)

                max_steps = calculate_max_steps(move)
                next unless next_position?(present_position,next_position,move,max_steps,move_direction)

                unit_move = calculate_unit_move(move,max_steps)
                check_for_intermediate_pieces(board, present_position, unit_move, max_steps, move_direction)
                
                return true
            end 
            raise "エラー!駒が動ける範囲外です"
        end

        # 駒が成れるかどうかを判定するメソッド
        def promotion_piece?(piece)
            RELEASION_PIECE_AND_PROMOTION_PIECE.key?(piece)
        end

        private 

        # 駒が歩かどうかを判定するメソッド
        def pawn?(piece)
            piece.downcase == "p"
        end

        # 指定列に二歩が存在するか検証するメソッド
        def validation_two_pawn(next_position,board,turn)
            col = next_position[1]
            target_pawn = turn ? "P" : "p"
            board.each_with_index do |row, i|
                next if i == next_position[0]
                return false if row[col] == target_pawn
            end
            true
        end

        def validate_two_pawn(piece,next_position, board, turn)
            if pawn?(piece)
                unless validation_two_pawn(next_position, board, turn)
                    raise "二歩です"
                end
            end
        end

        def can_piece_move_place?(next_position,move_direction,piece,board)
            unless can_move_validate(next_position, move_direction, piece, board)
                raise "その場所に駒は打てません"
            end
        end

        def can_move_validate(next_position, move_direction, piece, board)
            piece_object = PieceFactory::create_piece(piece)
            movement = piece_object.movement_patterns
            movement.any? do |move| 
                next_position_board_include?(next_position, move, move_direction)
            end
        end

        def next_position_board_include?(next_position, move, move_direction)
            target_row = next_position[0] + move_direction * move[1]
            target_col = next_position[1] - move_direction * move[0]
            (0..8).include?(target_row) && (0..8).include?(target_col)
        end

        def knight_next_position_move?(present_position, next_position, move, move_direction)
            target_row = present_position[0] + move_direction * move[1]
            target_col = present_position[1] - move_direction * move[0]
            target_row == next_position[0] && target_col == next_position[1]
        end

        # 駒を打つ場所が空いているか検証するメソッド
        def validate_place_empty(next_position,board)
            if board[next_position[0]][next_position[1]]
                raise "打つ場所に駒があります"
            end
        end

        # 持ち駒に指定された駒が存在するか検証するメソッド
        def validate_hand_exists(board, piece, turn)
            hand = turn ? board[HAND_INDEX_FIRST] : board[HAND_INDEX_SECOND]
            unless hand.include?(piece)
                raise "持ち駒が存在しません"
            end
        end
        
        def calculate_unit_move(move, max_steps)
            move.map { |i| i/ max_steps }
        end

        def calculate_max_steps(move)
            [move[0].abs, move[1].abs].max
        end

        def next_position_board_include?(next_position, move, move_direction)
            target_row = next_position[0] + move_direction * move[1]
            target_col = next_position[1] - move_direction * move[0]
            (0..8).include?(target_row) && (0..8).include?(target_col)
        end

        # 桂馬の移動かどうかを判定するメソッド
        def knight_move?(move)
            move == [1,2] || move == [-1,2]
        end

        def next_position?(present_position, next_position,move, max_steps, move_direction)
            target_row = present_position[0] + move_direction * move[1]
            target_col = present_position[1] - move_direction * move[0]
            target_row == next_position[0] && target_col == next_position[1]
        end

        def intermediate_piece?(board, present_position, unit_move,step, move_direction)
            intermediate_row = present_position[0] + move_direction * (unit_move[1] * step)
            intermediate_col = present_position[1] - move_direction * (unit_move[0] * step)
            board[intermediate_row][intermediate_col]
        end

        def check_for_intermediate_pieces(board, present_position, unit_move, max_steps, move_direction)
            (1...max_steps).each do |step|
                if intermediate_piece?(board, present_position, unit_move, step, move_direction)
                    raise "エラー！動かそうとしている位置の間に駒があります"
                end
            end
        end

        # 成れるかどうかをチェックするメソッド
        def promotion_validate(next_position,turn)
            if turn
                next_position[0] <= 2
            else
                next_position[0] >= 6
            end
        end
    end    
end