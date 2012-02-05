require 'fileutils'

require './down'

d =   Downloader.new 'http://www.wolnelektury.pl/katalog/' do
  traverse :head do |data, other|
    data.response.scan(/"(\/katalog\/autor\/[^"]+)"/).map do |url| 
      {
        :type => :author, 
        :url => 'http://www.wolnelektury.pl' + url[0], 
          :other => url[0].scan(/\/([^\/]+)\/$/)[0][0]
      } 
    end
  end
  
  traverse :author do |data, other|
    data.response.scan(/"([^\"]+.txt)"/).map do |url|
      {
        :type => :result,
        :url => 'http://www.wolnelektury.pl' + url[0],
        :other => {:title => url[0].scan(/\/([^\/]+)\.txt/)[0][0], :author=>other}
      }
    end
  end
  
  traverse :result do |data, other|
    claim_result({:text => data, :title => other[:title], :author => :other[:author]})
    []
  end
  
  process_results do |data, other|
    FileUtils.makedirs("stuff/#{other[:author]}/")
    File.open("stuff/#{other[:author][0]}/#{other[:title][0]}.txt", "w") do |file|
      file.puts data.response
    end
  end
end

d.run
