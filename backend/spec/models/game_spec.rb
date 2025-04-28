# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game, type: :model do
  describe 'DBスキーマ' do
    it 'modeカラムが存在し、デフォルト値がplayであること' do
      # カラムの存在確認
      expect(Game.column_names).to include('mode')
      # デフォルト値の確認
      game = Game.create!(status: 'active')
      expect(game.mode).to eq('play')
    end
  end
end 