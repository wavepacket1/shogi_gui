require 'spec_helper'
require_relative '../../pieces/base_piece'

RSpec.describe Shogi::Pieces::BasePiece do
    describe 'validate_movement' do 
        let(:board) { Array.new(9) { Array.new(9,nil)}}
        
        before do 
            piece.instance_variable_set(:@movement,[1,0])
        end
        describe '#validate_movement' do 
            
        end
    end
end