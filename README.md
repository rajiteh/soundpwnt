Sample settings.json file.
```
{
	"sources": {
		"soundcloud": {
			//Create a new soundcloud app from http://soundcloud.com/you/apps/new
		 	"client_id" : "",
		 	"prefix": "SC",
		 	//String array of api endpoints of playlists or user profiles (to get liked songs)
			"playlists": [
					 // i.e. : "/playlists/1234" or "/users/rajiteh"
				]
		}
	},
	"destinations" : {
		"dropbox" : {
			//Base remote path for the uploader to use. Should exist and be empty
			"remote_path": "",
			//Create a new dropbox app and use their web interface to generate app key, secret and access token
			"app_key": "",
			"app_secret": "",
			"access_token" : ""
		}
	}
}
```
