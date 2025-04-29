# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game, type: :model do
  describe '基本的な属性' do
    it 'ファクトリが有効であること' do
      game = build(:game)
      expect(game).to be_valid
    end

    it 'ステータスが正しく設定されていること' do
      game = create(:game, status: 'active')
      expect(game.status).to eq('active')
    end

    it 'デフォルトのモードがplayであること' do
      game = create(:game)
      expect(game.mode).to eq('play')
    end
  end

  describe 'アソシエーション' do
    it 'boardを持つこと' do
      game = create(:game)
      expect(game).to respond_to(:board)
    end

    it 'board_historiesを持つこと' do
      game = create(:game)
      expect(game).to respond_to(:board_histories)
    end

    it 'black_playerを持つこと' do
      black_player = create(:user)
      game = create(:game, black_player: black_player)
      expect(game.black_player).to eq(black_player)
    end

    it 'white_playerを持つこと' do
      white_player = create(:user)
      game = create(:game, white_player: white_player)
      expect(game.white_player).to eq(white_player)
    end
  end

  describe '#mode=' do
    let(:game) { create(:game, mode: 'play') }

    context '有効なモードに変更する場合' do
      it 'playからeditへの変更が成功すること' do
        game.mode = 'edit'
        expect(game.mode).to eq('edit')
      end

      it 'editからstudyへの変更が成功すること' do
        game.mode = 'edit'
        game.save
        game.mode = 'study'
        expect(game.mode).to eq('study')
      end

      it 'studyからplayへの変更が成功すること' do
        game.mode = 'study'
        game.save
        game.mode = 'play'
        expect(game.mode).to eq('play')
      end
    end

    context '無効なモードに変更する場合' do
      it '無効なモードの場合はエラーとなること' do
        expect { game.mode = 'invalid' }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#nyugyoku_declaration' do
    let(:game) { create(:game) }
    let(:board) { instance_double('Board', sfen: 'test_sfen') }
    
    before do
      allow(game).to receive(:board).and_return(board)
    end
    
    context '入玉宣言の条件を満たす場合' do
      it '入玉宣言が成功すること' do
        allow(Validator).to receive(:nyugyoku_27?).with('test_sfen').and_return(true)
        
        result = game.nyugyoku_declaration(board)
        
        expect(result).to eq(true)
      end
    end
    
    context '入玉宣言の条件を満たさない場合' do
      it '入玉宣言が失敗すること' do
        allow(Validator).to receive(:nyugyoku_27?).with('test_sfen').and_return(false)
        
        result = game.nyugyoku_declaration(board)
        
        expect(result).to eq(false)
      end
    end
  end
end 