namespace :erd do
    desc "Generate ER diagram"
    task generate: :environment do
        require 'rails_erd'
        
        begin
            RailsERD.options[:filename] = 'doc/erd'  # docディレクトリに出力
            RailsERD.options[:filetype] = :png       # PNG形式で出力
            RailsERD.options[:attributes] = [:primary_keys, :foreign_keys, :timestamps]
            RailsERD.options[:title] = "Shogi GUI ER"
            RailsERD.options[:notation] = :crowsfoot
            
            RailsERD::Diagram::Graphviz.create
            puts "ER図が doc/erd.png に生成されました"
        rescue => e
            puts "ER図の生成中にエラーが発生しました: #{e.message}"
        end
    end
end