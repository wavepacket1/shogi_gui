namespace :diagram do
    desc "Generate class diagram using YARD"

    
    def calculate_inheritance_depth(klass)
        return 0 unless klass  # klassがnilの場合は0を返す
        
        depth = 0
        current = klass
        
        while current && current.superclass && current.superclass.to_s != "Object"
            depth += 1
            current = YARD::Registry.at(current.superclass.to_s)
            break unless current  # 無限ループを防ぐ
        end
        
        depth
    end
    

    task generate: :environment do
        require 'yard'
        require 'fileutils'
        
        FileUtils.mkdir_p('doc')
        
        model_files = ['app/models/**/*.rb'] 
        
        YARD::Registry.clear
        YARD.parse(model_files)
        
        File.open("doc/class_diagram.dot", "w") do |f|
            f.puts "digraph G {"
            f.puts "  node [shape=box];"
            f.puts "  rankdir=TB;"
            f.puts "  splines=ortho;"  # 直角の線を使用
            f.puts "  nodesep=0.5;"    # ノード間の距離
            f.puts "  ranksep=0.5;"    # ランク間の距離

            # モジュールの生成（Concernsのみ）
            YARD::Registry.all(:module).each do |mod|
                next unless mod.path.include?('Concerns')
                f.puts "  \"#{mod.path}\" ["
                f.puts "    label=\"#{mod.name}\""
                f.puts "    shape=component"
                f.puts "    style=\"rounded,dashed\""
                f.puts "  ];"
            end
            
            # クラスノードの生成（クラス名のみ）
            YARD::Registry.all(:class).each do |klass|
                f.puts "  \"#{klass.path}\" ["
                f.puts "    label=\"#{klass.name}\""
                f.puts "  ];"
            end
            
            # 継承関係の出力（太さを調整）
            YARD::Registry.all(:class).each do |klass|
                if klass.superclass.to_s != "Object"
                    f.puts "  \"#{klass.superclass}\" -> \"#{klass.path}\" ["
                    f.puts "    arrowhead=empty,"
                    f.puts "    penwidth=2"
                    f.puts "  ];"
                end
            end

            f.puts "}"
        end
        
        begin
            result = system("dot -Tpng doc/class_diagram.dot -o doc/class_diagram.png")
            if result
                puts "クラス図が doc/class_diagram.png に生成されました"
            else
                puts "Error: dotコマンドの実行に失敗しました"
            end
        rescue StandardError => e
            puts "エラーが発生しました: #{e.message}"
        end
    end
end