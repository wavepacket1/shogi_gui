require 'spec_helper'
require_relative '../../pieces/base_piece'
require 'byebug'

RSpec.describe Shogi::Pieces::BasePiece do
    describe 'validate_movement' do 
        let(:board) { Array.new(9) { Array.new(9,nil)}}
        let(:present_position) { [6,4]}
        let(:move_direction) { -1 }

        context "桂馬の動きの場合" do 
            let(:movement) { [[1,2],[-1,2]] }
            let(:piece) { described_class.new(movement) }
            let(:next_position) { [5,6] }
            it '正しい動きであること'do 
                expect(piece.validate_movement(board,present_position,next_position,move_direction)).to be true
            end
        end

        context "動かす間に駒がある場合" do
            let(:movement) { [[0,1],[0,2],[0,3]] }
            let(:piece) { described_class.new(movement) }
            let(:next_position) { [4,4] }

            before do 
                board[5][4] = 'P'
            end
            it '動けないこと' do
                expect{ piece.validate_movement(board,present_position,next_position,move_direction) }.to raise_error("エラー！動かそうとしている位置の間に駒があります")
            end
        end

        context "駒が動ける範囲外の場合" do
            let(:movement) { [[0,1],[0,2],[0,3]] }
            let(:piece) { described_class.new(movement) }
            let(:next_position) { [1,1]}
            it '動けないこと' do 
                expect { piece.validate_movement(board,present_position,next_position,move_direction) }.to raise_error("エラー!駒が動ける範囲外です")
            end
        end
    end

    describe 'can_move_validation' do 
        let(:board) { Array.new(9) { Array.new(9,nil)}}
        let(:next_position) { [5,4] }
        let(:move_direction) { -1 }
        let(:movement) { [[1,2],[-1,2]]}
        let(:piece) { described_class.new(movement)}

        context '次の動きが盤面に収まるものが一つある時' do 
            before do 
                allow(piece).to receive(:next_position_board_include?).and_return(true) 
            end
            it ' trueを返すこと' do 
                expect(piece.can_move_validation(board,next_position,move_direction)).to be true
            end
        end

        context '次の動きが盤面に収まるものがない時' do 
            before do 
                allow(piece).to receive(:next_position_board_include?).and_return(false)
            end
            it 'falseを返すこと' do
                expect(piece.can_move_validation(board,next_position,move_direction)).to be false
            end
        end
    end
end