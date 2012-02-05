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
    claim_result({:text => data.response, :title => other[:title], :author => other[:author]})
    []
  end
  
  process_results do |result|
    FileUtils.makedirs("stuff/#{result[:author]}/")
    File.open("stuff/#{result[:author]}/#{result[:title]}.txt", "w") do |file|
      file.puts result[:text]
    end
  end
end

d.run
