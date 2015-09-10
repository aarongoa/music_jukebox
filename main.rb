require 'sinatra'
require './song'

# Reload if in development mode
require 'sinatra/reloader' if development?

configure do
	enable :sessions
	set :username, 'aaron'
	set :password, 'aaron'
end

# DB for development
configure :development do
	DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end

# DB for production
configure :production do
	DataMapper.setup(:default, ENV['DATABASE_URL'])
end

get '/' do
	@title = "Musical Jukebox"
	erb :home
end

get '/about' do
	@title = "About | Musical Jukebox"
	erb :about
end

get '/contact' do
	@title = "Contact | Musical Jukebox"
	erb :contact
end

get '/songs' do
	@songs = Song.all
	erb :songs
end

get '/login' do
	if session[:admin]
		redirect to ("/songs")
	end
	erb :login
end

get '/logout' do
	session.clear
	redirect to('/login')
end

get '/songs/new' do
	# Only works if admin logged in
	halt(401, erb(:not_authorized)) unless session[:admin]
	@song = Song.new
	erb :new_song
end

get '/songs/:id' do
	@song = Song.get(params[:id])
	erb :show_song
end

get '/songs/:id/edit' do
	@song = Song.get(params[:id])
	erb :edit_song
end

# Add song
post '/songs' do
	# Need to proted from direct post reqest that someone may try
	# since the form is accessible only to admin
	# Only works if admin logged in
	halt(401, erb(:not_authorized)) unless session[:admin]

	# To convert the entered time string to seconds instead of xx:xx format:
	# incoming data is in 'song' hash. 
	# create hash 'foo'. Use foo in the update method after formatting the length
	foo = params[:song]
	time = foo[:length].to_s.split(':')
	time = (time.first.to_i * 60 + time.last.to_i)
	foo[:length] = time

	song = Song.create(foo)
	redirect to("/songs/#{song.id}")
end

# Update song
put '/songs/:id' do
	# To convert the entered time string to seconds instead of xx:xx format:
	# incoming data is in 'song' hash. 
	# create hash 'foo'. Use foo in the update method after formatting the length
	foo = params[:song]
	time = foo[:length].to_s.split(':')
	time = (time.first.to_i * 60 + time.last.to_i)
	foo[:length] = time

	song = Song.get(params[:id])
	song.update(foo)
	redirect to("/songs/#{song.id}")
end

# Delete song
delete '/songs/:id' do
	# Only works if admin logged in
	halt(401, erb(:not_authorized)) unless session[:admin]
	Song.get(params[:id]).destroy
	redirect to('/songs')
end

post '/login' do
	if params[:username] == settings.username && params[:password] == settings.password
		session[:admin] = true
		redirect to('/songs')
	else
		erb :login
	end
end

not_found do
	@title = "Not Found | Musical Jukebox"
	erb :not_found
end
