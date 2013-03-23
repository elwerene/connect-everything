require 'sinatra'
require 'haml'
require 'data_mapper'

class Score
  include DataMapper::Resource
  
  property :id,         Serial    # An auto-increment integer key
  property :name,       String
  property :time,       String
  property :moves,      Integer
  property :difficulty, String
  property :points,     Float
  property :is_best_score, Boolean, default: false
  
  def update_best_score
    # find best score
    best = nil
    scoresSameName = Score.all(name: name, difficulty: difficulty);
    scoresSameName.each do |s|
      if best == nil || s.points > best.points
        best = s
      end
    end
    scoresSameName.each do |s|
      s.is_best_score = (s == best)
      s.save
    end
  end
end

class Item
  include DataMapper::Resource
 
  property :text, String,:key => true
end
 
configure do
  DataMapper.setup(:default, 'postgres://fela:@localhost/net-connect')
  DataMapper.finalize
  #DataMapper.auto_upgrade!
  #DataMapper.auto_migrate!
  DataMapper::Model.raise_on_save_failure = true

  #score = Score.create(name: "fela", time: '3:03', moves: 1, difficulty: 'easy', score: 13.33)
  #score = Score.create(name: 'fela', time: '3:03', moves: 1, difficulty: 'easy', points: 13.33)
  #score.save
end

helpers do  
  include Rack::Utils  
  alias_method :h, :escape_html
  
  def show_hiscores
    @scores = Score.all(order: [:points.desc])[0...30]
    haml :hiscores
  end
end  

get '/' do
  p Score.all;
  haml :index
end

post '/gamewon' do
  # params should contain: difficulty, time, moves and the score
  @params = params
  haml :submitscore#, locals: {score: score}
end

def get_or_post(path, opts={}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
end

post '/submitscore' do
  name = h params[:name][0...16]; # limit max size
  time = h params[:time];
  moves = (h params[:moves]).to_i
  difficulty = h params[:difficulty]
  points = params[:points]
  @newScore = Score.create(name: name, time: time, moves: moves, difficulty: difficulty, points: points)
  @newScore.save
  @newScore.update_best_score
  
  
  show_hiscores
end

get '/hiscores' do
  show_hiscores
end


