require 'rubygems'
require 'sinatra'
require 'json'

require 'chartkick'
require 'groupdate'
require 'pry'
require 'ai4r'
set :views, "#{settings.root}"

class Hash
  def each_count
    Hash[self.map{|k, v| [k, v.size] } ]
  end
end

def read_history
  file = File.read('history.json')
  chrome_history = JSON.parse(file)
  chrome_history.each{|record| record[:last_visit] = Time.new(1970, 1, 1, "+04:00")+record["lastVisitTime"]/1000}
end


get '/' do
  @history = read_history
  @by_date = @history.group_by_day{|r| r[:last_visit]}.each_count
  # binding.pry
  @by_hour = @history.group_by_hour_of_day{|r| r[:last_visit]}.each_count
  @by_day_of_week = @history.group_by_day_of_week{|r| r[:last_visit]}.each_count
  all_words = @history.map{|d| d["title"].split(" ")}.flatten.group_by {|x| x}.each_count
  @by_words = all_words.sort_by{|k,v| -v}.select{|a| a[0].size>3}.first(13)
  # @by_date = Hash[@history.group_by_day{|r| r[:last_visit]}.map{|k, v| [k, v.size] } ]
  erb :'index.html'
end

get '/sites' do
  erb :'sites.html'
end

get '/site_graph.json' do
  @history = read_history.sort_by{|r| r[:last_visit]}
  result = {:nodes =>[],:connections=>[]}

  @history.each_with_index do |record, i|
    loop do
      if @history[i+1] && (@history[i+1][:last_visit]-record[:last_visit])/60 < 5
        i+=1
        from = URI(record['url']).host rescue next
        to = URI(@history[i+1]['url']).host rescue next
        if from!=to
          connection = [from,to]
          result[:connections].push(connection)
        end
      else
        break
      end
    end
  end

  
  connections = result[:connections].group_by{|x| x}.each_count.to_a
  connections = connections.map{|c| c[0]<<c[1]}
  connections = connections.sort_by{|c| c[2]}.reverse.first(30)
  result[:connections] = connections
  result[:connections].each do |c|
    result[:nodes]<<c[0]
    result[:nodes]<<c[1]
  end
  result[:nodes].uniq!
  
  content_type :json
  result.to_json
end




