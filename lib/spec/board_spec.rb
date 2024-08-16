require 'spec_helper'
require_relative '../board'

RSpec.describe 'Board' do 
    describe 'ゲームスタート' do
        let(:board) { Shogi::Board.new }
        context "ゲームが始まる時" do 
            it "盤面が初期化されている" do 
                expect(board.initial_board).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                    ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
            end
        end
        context 'reset' do 
            it "盤面が初期化されること" do 
                expect(board.reset).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
            end
        end
    end

    describe 'move'do
    
    end

    describe 'validation' do 

    end

end

