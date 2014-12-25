#!/usr/bin/env ruby
require 'pp'
require 'logger'
require 'soundcloud'
require 'dbox'
require 'json'

OPTIONS_FILE = "settings.json"
if File.exists? OPTIONS_FILE
	@options = JSON.parse(File.read(OPTIONS_FILE))
else
	puts "You need to create a #{OPTIONS_FILE} file."
	exit
end

SC_CLIENT_ID = @options['sources']['soundcloud']['client_id']
SC_PREFIX = @options['sources']['soundcloud']['prefix']

DOWNLOAD_FOLDER = "downloads"
LOCAL_PATH = DOWNLOAD_FOLDER
REMOTE_PATH = @options['destinations']['dropbox']['remote_path']
ENV['DROPBOX_APP_KEY'] = @options['destinations']['dropbox']['app_key']
ENV['DROPBOX_APP_SECRET'] = @options['destinations']['dropbox']['app_secret']
ENV['DROPBOX_ACCESS_TOKEN'] = @options['destinations']['dropbox']['access_token']

Dir.mkdir DOWNLOAD_FOLDER unless Dir.exists? DOWNLOAD_FOLDER

log = Logger.new STDOUT
client = Soundcloud.new(:client_id => SC_CLIENT_ID)

options = {
	:prefix_playlist => true,
	:remove_orphans => true
}
list_endpoints = @options['sources']['soundcloud']['playlists']


# try to get a track
master_list = []
list_endpoints.each do |list_endpoint|
	log.info "Getting tracklist - #{list_endpoint}"
	begin
		result = client.get(list_endpoint)
	rescue Soundcloud::ResponseError => e
		puts "Error: #{e.message}, Status Code: #{e.response.code}"
	end
	if result.kind == "user"
		tracks = client.get("#{result.uri}/favorites")
		playlist_name = "#{result.permalink}'s Favorites"
	elsif result.kind == "playlist"
		tracks = result.tracks
		playlist_name = "#{result.title} (#{result.user.permalink})"
	end
	finished_tracks = []
	tracks.each do |track|
		begin
			track_name = "#{track.user.username} - #{track.title}.mp3".gsub(/(\\|\/|\*|:|>|<|\?|;|\[|\]|!)/, '_')
			track_path = File.join(DOWNLOAD_FOLDER, track_name)
			if File.exists? track_path
				log.warn "Exists - \"#{track_name}\""
			else
				log.info "Downloading - \"#{track_name}\""
				File.open(track_path, 'w') { |f| f.write client.get(track.stream_url) }
			end
			finished_tracks << track_name
		rescue
			log.fatal $!.message
			log.fatal track.stream_url
		end
	end
	prefixed_playlist_name = "#{options[:prefix_playlist] ? "#{SC_PREFIX} " : ''}#{playlist_name}.m3u8"
	Dir.chdir(DOWNLOAD_FOLDER) do
		log.info "Writing playlist - \"#{prefixed_playlist_name}\""
		File.open(prefixed_playlist_name, 'w') do |f|
			finished_tracks.each do |track|
				f.puts track
			end
		end
	end
	master_list.concat finished_tracks
end
master_list.uniq!
if options[:remove_orphans]
	Dir.chdir(DOWNLOAD_FOLDER) do
		Dir["*.mp3"].each do |f|
			#puts 'del'
			#puts f unless master_list.include? f
			#File.delete(f) unless master_list.include? f
		end
	end
end

log.info "Uploading to dropbox folder \"#{REMOTE_PATH}\""
LOGGER = log
LOGGER.level = Logger::INFO
unless Dbox.exists? LOCAL_PATH
	Dbox.clone(REMOTE_PATH, LOCAL_PATH)
else
	Dbox.push(DOWNLOAD_FOLDER)
end
