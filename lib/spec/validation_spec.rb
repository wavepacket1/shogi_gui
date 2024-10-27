require 'spec_helper'
require_relative '../validation'

RSpec.describe 'Validation' do 
    #駒を動かす時に合法手かどうかの判定
    describe 'check_move?' do 
        before do 
            allow(Validation).to receive(:check_detection?).and_return(false)
        end
        #移動するマス目の間に駒がないかどうかの判定
        context '移動するマス目の間に駒がない場合' do 
            before do 
                allow(Validation).to receive(:check_piece_between?).and_return(false)
            end
            it 'trueが返ること' do 
                expect(Validation::check_move?).to be true
            end
        end

        context '移動するマス目の間に駒がある場合' do 
            before do 
                allow(Validation).to receive(:check_piece_between?).and_return(true)
            end
            it ''
        end


    end
    #駒を打つ時に合法手かどうかの判定
    describe 'check_piece_drop?' do 

    end
    #駒を成る時に合法手かどうかの判定
    describe 'check_promotion?' do 

    end

    #王手判定
    describe 'check_detection?' do 

    end

    describe 'check_usi_protocol?' do 
        context '文字列でない場合' do 
            let(:invalid_usi_protocol) { 1223243 }
            it 'falseが返ること' do
                expect(Validation::check_usi_protocol?(invalid_usi_protocol)).to be false
            end
        end
        context '+が含まれている場合' do
            let(:valid_usi_protocol) { '7g7f+' }
            let(:invalid_usi_protocol) { '7g7g+' }
            it 'trueが返ること' do 
                expect(Validation::check_usi_protocol?(valid_usi_protocol)).to be true
            end

            it 'falseが返ること' do
                expect(Validation::check_usi_protocol?(invalid_usi_protocol)).to be false
            end
        end

        context '*が含まれている場合' do
            let(:valid_usi_protocol) { 'G*5b' }
            let(:invalid_usi_protocol) { 'G*5B' }
            let(:invalid_usi_protocol2) { 'G*5gewagae' }
            it 'trueが返ること' do 
                expect(Validation::check_usi_protocol?(valid_usi_protocol)).to be true
            end

            it 'falseが返ること' do
                expect(Validation::check_usi_protocol?(invalid_usi_protocol)).to be false
            end

            it 'falseが返ること' do
                expect(Validation::check_usi_protocol?(invalid_usi_protocol2)).to be false
            end
        end

        context 'それ以外の場合' do 
            let(:valid_usi_protocol) { '7g7f' }
            let(:invalid_usi_protocol) { '7g7g' }
            it 'trueが返ること' do 
                expect(Validation::check_usi_protocol?(valid_usi_protocol)).to be true
            end

            it 'falseが返ること' do
                expect(Validation::check_usi_protocol?(invalid_usi_protocol)).to be false
            end
        end
    end

    describe 'check_turn_and_piece?' do 
        let(:turn) { true}
        context '先手番で後手番の駒を動かそうとした場合' do

        end
    end
end