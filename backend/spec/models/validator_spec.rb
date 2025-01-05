require 'rails_helper'

RSpec.describe Validator, type: :model do
    let(:empty_board) { Array.new(9) { Array.new(9) } }

    describe '#in_check?' do 
        it 'returns true when the king is in check from a rook' do
            board = empty_board.dup
            board[4][4] = 'K'  # 王の位置
            board[4][6] = 'r'  # 敵の飛車の位置
        
            expect(described_class.in_check?(board, 'b')).to be true
        end
        
        it 'returns false when the king is not in check' do
            board = empty_board.dup
            board[4][4] = 'K'  # 王の位置
            board[2][2] = 'r'  # 敵の飛車が遠くにいる
        
            expect(described_class.in_check?(board, 'b')).to be false
        end
        
        it 'returns true if the king is missing' do
            board = empty_board.dup
        
            expect(described_class.in_check?(board, 'b')).to be true
        end
        
        it 'returns true when the king is in check from a promoted piece' do
            board = empty_board.dup
            board[4][4] = 'K'  # 王の位置
            board[3][4] = '+b' # 敵の成銀（promoted bishop）
        
            expect(described_class.in_check?(board, 'b')).to be true
        end
    end

    describe '#will_check?' do
        it '飛車から王手になる場合はtrueを返す' do
            board = empty_board.dup
            board[4][4] = 'k'  # 敵の王の位置
            board[4][6] = 'R'  # 自陣の飛車の位置
        
            expect(described_class.will_check?(board, 'b', {piece_type: 'R', from_row: 4, from_col: 6, to_row: 4, to_col: 4})).to be true
        end

        
    end
end
