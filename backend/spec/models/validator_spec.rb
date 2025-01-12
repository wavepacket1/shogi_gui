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
        it 'returns false when the move does not put the opponent\'s king in check' do
            board = empty_board.dup
            board[4][4] = 'k'  # 敵の王の位置
            board[2][2] = 'R'  # 自陣の飛車の位置

            move_info = { piece_type: 'R', from_row: 2, from_col: 2, to_row: 2, to_col: 3 }

            expect(described_class.will_check?(board, 'b', move_info)).to be false
        end

        it 'returns false if the opponent\'s king is missing' do
            board = empty_board.dup
            # 敵の王が盤面に存在しない

            move_info = { piece_type: 'R', from_row: 2, from_col: 2, to_row: 2, to_col: 3 }

            expect(described_class.will_check?(board, 'b', move_info)).to be false
        end

        it 'returns true when the move involves a promoted piece putting the king in check' do
            board = empty_board.dup
            board[4][4] = 'k'  # 敵の王の位置
            board[3][4] = '+B' # 自陣の成角の位置

            move_info = { piece_type: '+B', from_row: 3, from_col: 4, to_row: 4, to_col: 4 }

            expect(described_class.will_check?(board, 'b', move_info)).to be true
        end
    end
    
    describe '.is_checkmate?' do 
        let(:board) { Array.new(9) { Array.new(9, nil) } }

        context '王手がかかっていない時' do
            it 'falseを返す' do 
                allow(described_class).to receive(:in_check?).with(board, 'b').and_return(false)
                expect(described_class.is_checkmate?(board, 'b')).to be false
            end
        end

        context '王手がかかっている時' do 
            context '持ち駒を使わない時' do 
                context '逃げる手がある時' do
                    it 'falseを返す' do 
                        allow(described_class).to receive(:in_check?).with(board, 'b').and_return(false)
                        expect(described_class.is_checkmate?(board, 'b')).to be false
                    end
                end

                context '詰んでいる時' do 
                    it 'trueを返す' do 
                        allow(described_class).to receive(:in_check?).with(board, 'b').and_return(true)
                        allow(described_class).to receive(:check_hands).with(board, 'b').and_return(true)
                        expect(described_class.is_checkmate?(board, 'b')).to be true
                    end
                end
            end
        end
    end
end
