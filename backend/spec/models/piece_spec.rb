require 'rails_helper'

RSpec.describe Piece, type: :model do
  describe 'クラスメソッド' do
    describe '.promote_piece' do
      it '駒を成り駒に変換すること' do
        expect(Piece.promote_piece('P')).to eq('+P')
      end
    end

    describe '.valid_from_piece?' do
      context '先手の場合' do
        let(:side) { 'b' }

        it '先手の駒であれば有効と判断すること' do
          expect(Piece.valid_from_piece?('P', side)).to be true
        end

        it '後手の駒であれば無効と判断すること' do
          expect(Piece.valid_from_piece?('p', side)).to be false
        end

        it '駒がない場合は無効と判断すること' do
          expect(Piece.valid_from_piece?(nil, side)).to be false
        end
      end

      context '後手の場合' do
        let(:side) { 'w' }

        it '後手の駒であれば有効と判断すること' do
          expect(Piece.valid_from_piece?('p', side)).to be true
        end

        it '先手の駒であれば無効と判断すること' do
          expect(Piece.valid_from_piece?('P', side)).to be false
        end
      end
    end

    describe '.valid_to_piece?' do
      context '先手の場合' do
        let(:side) { 'b' }

        it '空白のマスは有効と判断すること' do
          expect(Piece.valid_to_piece?(nil, side)).to be true
        end

        it '後手の駒は有効と判断すること（取れる）' do
          expect(Piece.valid_to_piece?('p', side)).to be true
        end

        it '先手の駒は無効と判断すること（取れない）' do
          expect(Piece.valid_to_piece?('P', side)).to be false
        end
      end

      context '後手の場合' do
        let(:side) { 'w' }

        it '空白のマスは有効と判断すること' do
          expect(Piece.valid_to_piece?(nil, side)).to be true
        end

        it '先手の駒は有効と判断すること（取れる）' do
          expect(Piece.valid_to_piece?('P', side)).to be true
        end

        it '後手の駒は無効と判断すること（取れない）' do
          expect(Piece.valid_to_piece?('p', side)).to be false
        end
      end
    end

    describe '.capture_piece!' do
      it '先手が駒を取った場合、正しく手駒に追加されること' do
        hand = {}
        Piece.capture_piece!('p', hand, 'b')
        expect(hand).to eq({ 'P' => 1 })
      end

      it '後手が駒を取った場合、正しく手駒に追加されること' do
        hand = {}
        Piece.capture_piece!('P', hand, 'w')
        expect(hand).to eq({ 'p' => 1 })
      end

      it '成り駒が取られた場合、基本形に戻して手駒に追加されること' do
        hand = {}
        Piece.capture_piece!('+P', hand, 'b')
        expect(hand).to eq({ 'P' => 1 })
      end

      it '既に同じ種類の手駒がある場合、数が増えること' do
        hand = { 'P' => 1 }
        Piece.capture_piece!('p', hand, 'b')
        expect(hand).to eq({ 'P' => 2 })
      end
    end

    describe '.drop_target_empty?' do
      it '空のマスには駒を打てること' do
        board_array = Array.new(9) { Array.new(9, nil) }
        expect(Piece.drop_target_empty?(board_array, 0, 0)).to be true
      end

      it '既に駒があるマスには駒を打てないこと' do
        board_array = Array.new(9) { Array.new(9, nil) }
        board_array[0][0] = 'P'
        expect(Piece.drop_target_empty?(board_array, 0, 0)).to be false
      end
    end
  end
end
