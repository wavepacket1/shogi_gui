require 'spec_helper'
require_relative '../../pieces/p.rb'

RSpec.describe Shogi::Pieces do 
    describe 'Piece Movement Validation' do 
        let(:board) do 
            Array.new(9) { Array.new(9,nil)}
        end
        context 'Pawn(P)' do
            describe Shogi::Pieces::P do 
                let(:present_position) { [6,4] }
                let(:move_direction) { -1}

                it 'allows moving forward by one square' do
                    next_position = [5,4]
                    expect(Shogi::Pieces::P.new.validate_movement(board,present_position,next_position,move_direction)).to be true
                end

                it 'disallows moving sideways' do 
                    next_position = [6,5]
                    expect(Shogi::Pieces::P.new.validate_movement(board,present_position,next_position,move_direction)).to be false
                end

                it 'disallows moving backward' do 
                    next_position = [7,4]
                    expect(Shogi::Pieces::P.new.validate_movement(board,present_position,next_position,move_direction)).to be false
                end
            end
        end
    end
end