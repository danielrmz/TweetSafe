#!/usr/bin/ruby

require 'rubygems'
require 'twitter'
require 'parseconfig'
require 'pp'
require 'mongo'

config = ParseConfig.new('config')

oauth = Twitter::OAuth.new(config.get_value("consumer_token"),config.get_value("consumer_secret"))  
oauth.authorize_from_access(config.get_value("access_token"),config.get_value("access_secret")) 

begin
	client = Twitter::Base.new(oauth)
	db = Mongo::Connection.new(config.get_value("mongo_host"),config.get_value("mongo_port")).db(config.get_value("mongo_db"))
	db.authenticate(config.get_value("mongo_user"),config.get_value("mongo_pass"))

	# Establecemos la BD a usar
	coll = db.collection(config.get_value("mongo_tweet_collection"))

	# Obtenemos el ultimo tweet guardado
	last = coll.find_one({},{:fields=>[:id,:created_at],:sort=>[:created_at,'descending']})	
	
	client.friends_timeline({:since_id=>last['id'],:count=>200}).each { |tweet| coll.insert(tweet) }

rescue OAuth::Unauthorized
	puts "[ERROR] Unauthorized!"
end
