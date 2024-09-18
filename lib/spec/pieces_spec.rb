# spec/pieces_spec.rb
require 'spec_helper'
require_relative '../pieces'

RSpec.describe Shogi::Pieces do
    describe 'Piece Movement Validation' do
        let(:board) do 
            Array.new(9) { Array.new(9,nil)}
        end

        context 'Pawn(P)' do 
            describe Shogi::Pieces::P do 
                let(:present_position) { [6,4] }
                let(:move_direction) { -1 }

                it 'allows moving forward by one square' do
                    next_position = [5,4]
                    expect(Shogi::Pieces::P.new.validate_movement(board,present_position,next_position,move_direction)).to be true
                end

                it 'disallows moving sideways' do
                    next_position = [6, 5]
                    expect(Shogi::Pieces::P.new.validate_movement(board, present_position, next_position, move_direction)).to be false
                end
        
                it 'disallows moving backward' do
                    next_position = [7, 4]
                    expect(Shogi::Pieces::P.new.validate_movement(board, present_position, next_position, move_direction)).to be false
                end
        
                it 'disallows moving if the target square is occupied by own piece' do
                    board[5][4] = 'P' # 自分の駒がいる
                    next_position = [5, 4]
                    expect(Shogi::Pieces::P.new.validate_movement(board, present_position, next_position, move_direction)).to be true
                    # 上記では駒の存在をチェックしていないため、別途`Shogi::Board`側でチェックする必要があります
                end
        
                it 'allows moving if the target square is occupied by opponent piece' do
                    board[5][4] = 'p' # 相手の駒がいる
                    next_position = [5, 4]
                    expect(Shogi::Pieces::P.new.validate_movement(board, present_position, next_position, move_direction)).to be true
                end
            end
        end
    end
end