require 'spec_helper'
require_relative '../board'

RSpec.describe 'Board' do 
    describe 'ゲームスタート' do
        let(:shogi_board) { Shogi::Board.new }
        context "ゲームが始まる時" do 
            it "盤面が初期化されている" do 
                expect(shogi_board.initial_board).to eq([
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
                expect(shogi_board.reset).to eq([
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
        before do 
            @shogi_board = Shogi::Board.new
        end
        context "歩が動く時" do 
            context '先手番の時' do
                it '１マス前に動けること' do 
                    @shogi_board.move("7776P")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ]
                    )
                end

                it '成ることができること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("3435p")
                    @shogi_board.move("7574P")
                    @shogi_board.move("3536p")
                    @shogi_board.move("7473PT")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "T", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        ["P"],#先手の持ち駒
                        [],#後手の持ち駒
                    ]
                    )
                end

                it '二歩の時、エラーが出ること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("3435p")
                    @shogi_board.move("7574P")
                    @shogi_board.move("3536p")
                    @shogi_board.move("7473PT")
                    @shogi_board.move("8384p")
                    expect { @shogi_board.move("H066P") }.to raise_error("二歩です")
                end
            end

            context "後手番の時" do 
                it '１マス前に動けること' do
                    @shogi_board.move('7776P')
                    @shogi_board.move('3334p')
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ]
                    )
                end

                it '成ることができること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("3435p")
                    @shogi_board.move("7574P")
                    @shogi_board.move("3536p")
                    @shogi_board.move("8786P")
                    @shogi_board.move("3637pt")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, "P", nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", nil, nil, "P", "P", "P", "t", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        ["p"],#後手の持ち駒
                    ]
                    )
                end

                it '二歩の時、エラーが出ること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("3435p")
                    @shogi_board.move("7574P")
                    @shogi_board.move("3536p")
                    @shogi_board.move("8786P")
                    @shogi_board.move("3637pt")
                    @shogi_board.move("8685P")
                    expect { @shogi_board.move("H144p") }.to raise_error("二歩です")
                end
            end
        end

        context "香車" do 
            context "先手番の時" do 
                it '１マス前に動けること' do 
                    @shogi_board.move("9998L")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        ["L", "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        [nil, "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ]
                    )
                end

                it '2マス前に進めること' do
                    @shogi_board.move("9796P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("9997L")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        ["P", nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["L", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        [nil, "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ]
                    )
                end

                it '成ることができること' do 
                    @shogi_board.move("9796P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("9695P")
                    @shogi_board.move("3435p")
                    @shogi_board.move("9594P")
                    @shogi_board.move("3536p")
                    @shogi_board.move("9493PT")
                    @shogi_board.move("4344p")
                    @shogi_board.move("9392T")
                    @shogi_board.move("4445p")
                    @shogi_board.move("9993LY")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        ["T", "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["Y", "p", "p", "p", "p", nil, nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, "p", nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P6
                        [nil, "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        [nil, "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        ["P"],#先手の持ち駒
                        [],#後手の持ち駒
                    ]
                    )
                end
            end

            context "後手番の時" do
                it '１マス前に動けること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("1112l")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                            ["l", "n", "s", "g", "k", "g", "s", "n", nil], # P1
                            [nil, "r", nil, nil, nil, nil, nil, "b", "l"], # P2
                            ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                            [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                            [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                            [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                            ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                            [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                            ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                            [],#先手の持ち駒
                            [],#後手の持ち駒
                        ]
                        )
                end

                it '2マス前に進めること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("1314p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("1113l")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                            ["l", "n", "s", "g", "k", "g", "s", "n", nil], # P1
                            [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                            ["p", "p", "p", "p", "p", "p", "p", "p", "l"], # P3
                            [nil, nil, nil, nil, nil, nil, nil, nil, "p"], # P4
                            [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P5
                            [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                            ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                            [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                            ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                            [],#先手の持ち駒
                            [],#後手の持ち駒
                        ]
                    )
                end

                it '成ることができること' do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("1314p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("1415p")
                    @shogi_board.move("7574P")
                    @shogi_board.move("1516p")
                    @shogi_board.move("6766P")
                    @shogi_board.move("1617pt")
                    @shogi_board.move("6665P")
                    @shogi_board.move("1718t")
                    @shogi_board.move("6564P")
                    @shogi_board.move("1117ly")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", nil], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", nil], # P3
                        [nil, nil, "P", "P", nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, nil, "P", "P", "P", "P", "y"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", "t"], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        ["p"],#後手の持ち駒
                    ]
                )
                end
            end
        end

        context "桂馬" do 
            context "先手番の時" do 
                it "(1,2)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8977N")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "N", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", nil, "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,-2)に動けること" do 
                    @shogi_board.move("9796P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8997N")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        ["P", nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["N", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", nil, "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "成ることができること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8977N")
                    @shogi_board.move("3435p")
                    @shogi_board.move("7765N")
                    @shogi_board.move("3536p")
                    @shogi_board.move("6553NE")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "E", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, "p", nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", nil, "S", "G", "K", "G", "S", "N", "L"], # P9
                        ["P"],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end
            end

            context "後手番の時" do 
                it "(1,2)に動けること" do
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("2133n")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", nil, "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "n", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,-2)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("1314p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("2113n")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", nil, "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "n"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, "p"], # P4
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "成ることができること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("2133n")
                    @shogi_board.move("7574P")
                    @shogi_board.move("3345n")
                    @shogi_board.move("6766P")
                    @shogi_board.move("4557ne")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", nil, "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, "P", nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, "P", nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, nil, "e", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        ["p"],#後手の持ち駒
                    ])
                end
            end
        end

        context "銀" do 
            context  "先手番の時" do
                it "(0,1)に動けること" do 
                    @shogi_board.move("7978S")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", "S", nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", nil, "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,1)に動けること" do
                    @shogi_board.move("7968S")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, "S", nil, nil, nil, "R", nil], # P8
                        ["L", "N", nil, "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(-1,1)に動けること" do 
                    @shogi_board.move("3948S")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, "S", nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", nil, "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,-1)に動けること" do 
                    @shogi_board.move("3948S")
                    @shogi_board.move("3334p")
                    @shogi_board.move("4839S")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(-1,-1)に動けること" do 
                    @shogi_board.move("7968S")
                    @shogi_board.move("3334p")
                    @shogi_board.move("6879S")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "成ることができること" do
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7968S")
                    @shogi_board.move("3435p")
                    @shogi_board.move("6877S")
                    @shogi_board.move("3536p")
                    @shogi_board.move("7766S")
                    @shogi_board.move("4344p")
                    @shogi_board.move("6665S")
                    @shogi_board.move("4445p")
                    @shogi_board.move("6564S")
                    @shogi_board.move("4546p")
                    @shogi_board.move("6463SI")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "I", "p", nil, nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, "p", "p", nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", nil, "G", "K", "G", "S", "N", "L"], # P9
                        ["P"],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end
            end

            context "後手番の時" do 
                it "(0,1)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3132s")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", nil, "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, "s", "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,1)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("7162s")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", nil, "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, "s", nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,-1)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3142s")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", nil, "n", "l"], # P1
                        [nil, "r", nil, nil, nil, "s", nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(1,-1)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3142s")
                    @shogi_board.move("7675P")
                    @shogi_board.move("4231s")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "(-1,-1)に動けること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("7162s")
                    @shogi_board.move("7675P")
                    @shogi_board.move("6271s")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                    ])
                end

                it "成ることができること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("7675P")
                    @shogi_board.move("3132s")
                    @shogi_board.move("7574P")
                    @shogi_board.move("3233s")
                    @shogi_board.move("6766P")
                    @shogi_board.move("3344s")
                    @shogi_board.move("6665P")
                    @shogi_board.move("4455s")
                    @shogi_board.move("6564P")
                    @shogi_board.move("5546s")
                    @shogi_board.move("9796P")
                    @shogi_board.move("4647si")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", nil, "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, "P", "P", nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        ["P", nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        [nil, "P", nil, nil, "P", "i", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        ["p"],#後手の持ち駒
                    ])
                end
            end
        end

        context "金" do 
            context "先手番の時" do 
                it "(0,1)に動けること" do 
                    @shogi_board.move("6968G")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", nil, "G", nil, nil, nil, "R", nil], # P8
                    ["L", "N", "S", nil, "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
                end

                it "(1,1)に動けること" do 
                    @shogi_board.move("6958G")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", nil, nil, "G", nil, nil, "R", nil], # P8
                    ["L", "N", "S", nil, "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
                end

                it "(1,-1)に動けること" do 
                    @shogi_board.move("6978G")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", "G", nil, nil, nil, nil, "R", nil], # P8
                    ["L", "N", "S", nil, "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
                end


                it "(1,0)に動けること" do 
                    @shogi_board.move("6968G")
                    @shogi_board.move("3334p")
                    @shogi_board.move("6858G")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", nil, nil, "G", nil, nil, "R", nil], # P8
                    ["L", "N", "S", nil, "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
                end

                it "(-1,0)に動けること" do 
                    @shogi_board.move("6968G")
                    @shogi_board.move("3334p")
                    @shogi_board.move("6878G")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", "G", nil, nil, nil, nil, "R", nil], # P8
                    ["L", "N", "S", nil, "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
                end

                it "(0,-1)に動けること" do 
                    @shogi_board.move("6968G")
                    @shogi_board.move("3334p")
                    @shogi_board.move("6869G")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
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

        context "王" do 
            context "先手番の時" do 
                it "(0,1)に動けること" do 
                    @shogi_board.move("5958K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, "K", nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", nil, "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "(1,1)に動けること" do 
                    @shogi_board.move("5948K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, "K", nil, "R", nil], # P8
                        ["L", "N", "S", "G", nil, "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "(-1,1)に動けること" do 
                    @shogi_board.move("5968K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, "K", nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", nil, "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "(0,-1)に動けること" do 
                    @shogi_board.move("5958K")
                    @shogi_board.move("3334p")
                    @shogi_board.move("5859K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
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

                it "(-1,-1)に動けること" do 
                    @shogi_board.move("5948K")
                    @shogi_board.move("3334p")
                    @shogi_board.move("4859K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
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

                it "(1,-1)に動けること" do 
                    @shogi_board.move("5948K")
                    @shogi_board.move("3334p")
                    @shogi_board.move("4859K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
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

                it "(1,0)に動けること" do
                    @shogi_board.move("5958K")
                    @shogi_board.move("3334p")
                    @shogi_board.move("5848K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, nil, nil, "K", nil, "R", nil], # P8
                        ["L", "N", "S", "G", nil, "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "(-1,0)に動けること" do
                    @shogi_board.move("5958K")
                    @shogi_board.move("3334p")
                    @shogi_board.move("5868K")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, "B", nil, "K", nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", nil, "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end
            end
        end

        context "飛車" do 
            it "縦に1マス動かせること" do 
                @shogi_board.move("2726P")
                @shogi_board.move("3334p")
                @shogi_board.move("2827R")
                expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, "P", nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "R", "P"], # P7
                    [nil, "B", nil, nil, nil, nil, nil, nil, nil], # P8
                    ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
            end

            it "縦に2マス動かせること" do 
                @shogi_board.move("2726P")
                @shogi_board.move("3334p")
                @shogi_board.move("2625P")
                @shogi_board.move("3435p")
                @shogi_board.move("2826R")
                expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, "p", "P", nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, "R", nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", nil, "P"], # P7
                    [nil, "B", nil, nil, nil, nil, nil, nil, nil], # P8
                    ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
            end

            it "横に1マス動かせること" do 
                @shogi_board.move("2858R")
                expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                    ["p", "p", "p", "p", "p", "p", "p", "p", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                    [nil, "B", nil, nil, "R", nil, nil, nil, nil], # P8
                    ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                    [],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
            end

            it "成れること" do 
                @shogi_board.move("2726P")
                @shogi_board.move("3334p")
                @shogi_board.move("2625P")
                @shogi_board.move("3435p")
                @shogi_board.move("2524P")
                @shogi_board.move("3536p")
                @shogi_board.move("2423PT")
                @shogi_board.move("4344p")
                @shogi_board.move("2332T")
                @shogi_board.move("4445p")
                @shogi_board.move("2823RZ")
                expect(@shogi_board.instance_variable_get(:@board)).to eq([
                    ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                    [nil, "r", nil, nil, nil, nil, "T", "b", nil], # P2
                    ["p", "p", "p", "p", "p", nil, nil, "Z", "p"], # P3
                    [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                    [nil, nil, nil, nil, nil, "p", nil, nil, nil], # P5
                    [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P6
                    ["P", "P", "P", "P", "P", "P", "P", nil, "P"], # P7
                    [nil, "B", nil, nil, nil, nil, nil, nil, nil], # P8
                    ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                    ["P"],#先手の持ち駒
                    [],#後手の持ち駒
            ]
                )
            end
        end

        context "角" do 
            context "先手番の時" do 
                it "右斜め上に1マス動かせること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8877B")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", "B", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, nil, nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "右斜め上に2マス動かせること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8866B")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", "B", nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, nil, nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "左斜め上に1マス動かせること" do 
                    @shogi_board.move("9796P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8897B")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        ["P", nil, nil, nil, nil, nil, nil, nil, nil], # P6
                        ["B", "P", "P", "P", "P", "P", "P", "P", "P"], # P7
                        [nil, nil, nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "左斜め上に2マス動かせること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8877B")
                    @shogi_board.move("3435p")
                    @shogi_board.move("7795B")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", nil, "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P4
                        ["B", nil, nil, nil, nil, nil, "p", nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, nil, nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end

                it "成ることができること" do 
                    @shogi_board.move("7776P")
                    @shogi_board.move("3334p")
                    @shogi_board.move("8833BU")
                    expect(@shogi_board.instance_variable_get(:@board)).to eq([
                        ["l", "n", "s", "g", "k", "g", "s", "n", "l"], # P1
                        [nil, "r", nil, nil, nil, nil, nil, "b", nil], # P2
                        ["p", "p", "p", "p", "p", "p", "U", "p", "p"], # P3
                        [nil, nil, nil, nil, nil, nil, "p", nil, nil], # P4
                        [nil, nil, nil, nil, nil, nil, nil, nil, nil], # P5
                        [nil, nil, "P", nil, nil, nil, nil, nil, nil], # P6
                        ["P", "P", nil, "P", "P", "P", "P", "P", "P"], # P7
                        [nil, nil, nil, nil, nil, nil, nil, "R", nil], # P8
                        ["L", "N", "S", "G", "K", "G", "S", "N", "L"], # P9
                        [],#先手の持ち駒
                        [],#後手の持ち駒
                ]
                    )
                end
            end
        end

        context "validation error" do 

        end
    end
end

