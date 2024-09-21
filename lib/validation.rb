require 'yaml' 
require_relative 'pieces'
require_relative 'board'

# YAMLファイルの読み込み
CONFIG = YAML.load_file(File.join(__dir__,'config/constants.yml'))
#定数の定義
HAND_INDEX_FIRST = CONFIG['HAND_INDEX_FIRST']
HAND_INDEX_SECOND = CONFIG['HAND_INDEX_SECOND']

# 持ち駒キーと対応する手駒インデックスのマッピング
PLAYER_HAND_INDEX = CONFIG['PLAYER_HAND_INDEX']
RELEASION_PIECE_AND_PROMOTION_PIECE = CONFIG['RELEASION_PIECE_AND_PROMOTION_PIECE'].freeze

class Validation
    attr_accessor :board,:current_player

    # 持ち駒に指定された駒が存在するか検証するメソッド
    def self.validate_hand_exists(board,piece,turn)
        hand = turn ? board[HAND_INDEX_FIRST] : board[HAND_INDEX_SECOND]
        unless hand.include?(piece)
            raise "持ち駒が存在しません"
        end
    end

    def self.validate_can_move(next_position,move_direction,piece,board)
        unless self.can_move_validation(next_position, move_direction, piece,board)
            raise "その場所に駒は打てません"
        end
    end

    # 現在のターンとmove_protocolの駒が一致するか検証するメソッド
    def self.validate_turn(move_protocol,turn)
        last_char = move_protocol[-1]
        if last_char =~ /[A-Z]/ && !turn
            raise "先手番を２回続けて動かすことはできません"
        elsif last_char =~ /[a-z]/ && turn
            raise "後手番を２回続けて動かすことはできません"
        end
    end

    # 移動が有効か検証するメソッド
    def self.valid_move?(board,piece,present_position,next_position,move_direction)
        current_piece = board[present_position[0]][present_position[1]]
        return false unless current_piece == piece

        self.piece_validation(piece, present_position, next_position, move_direction,board)
    end
    
    # 成れるかどうかをチェックするメソッド
    def self.promotion_validation(next_position,turn)
        if turn
            next_position[0] <= 2
        else
            next_position[0] >= 6
        end
    end

    # 駒の移動検証を行うメソッド
    def self.piece_validation(piece,present_position,next_position,move_direction,board)
        piece_object = self.create_piece_object(piece)
        unless piece_object.validate_movement(board,present_position,next_position,move_direction)
            raise "不明な駒: #{piece}"
        end
        true
    end


    # 駒を打つ際の検証を行うメソッド
    def self.strike_piece_validation(piece,next_position,move_direction,board,turn)
        self.validate_hand_exists(board,piece,turn)
        self.validate_place_empty(next_position,board)
        self.validate_can_move(next_position, move_direction, piece,board)
        self.validate_two_pawn(piece, next_position,board,turn)
        true
    end

    # 駒を打つ場所が空いているか検証するメソッド
    def self.validate_place_empty(next_position,board)
        if board[next_position[0]][next_position[1]]
            raise "打つ場所に駒があります"
        end
    end

    def self.validate_two_pawn(piece,next_position,board,turn)
        if pawn?(piece)
            unless self.validation_two_pawn(next_position,board,turn)
                raise "二歩です"
            end
        end
    end

    # 指定列に二歩が存在するか検証するメソッド
    def self.validation_two_pawn(next_position,board,turn)
        col = next_position[1]
        target_pawn = turn ? "P" : "p"
        board.each_with_index do |row, i|
            next if i == next_position[0]
            return false if row[col] == target_pawn
        end
        true
    end

    # 駒が指定位置に動けるか検証するメソッド
    def self.can_move_validation(next_position, move_direction, piece,board)
        piece_object = self.create_piece_object(piece)
        unless piece_object.can_move_validation(board,next_position,move_direction)
            raise "不明な駒: #{piece}"
        end
        true
    end

    # 駒が成れるかどうかを判定するメソッド
    def self.promotion_piece?(piece)
        RELEASION_PIECE_AND_PROMOTION_PIECE.key?(piece)
    end

    private
    def self.create_piece_object(piece)
        Shogi::Pieces.const_get(piece.upcase).new
    rescue NameError
        raise "不明な駒: #{piece}"
    end

    # 駒が歩かどうかを判定するメソッド
    def self.pawn?(piece)
        piece.downcase == "p"
    end
end