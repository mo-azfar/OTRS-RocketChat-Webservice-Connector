#OTRS-RocketChat Generic Interface
- Built for OTRS CE v6.0
- This module enable the integration from RocketChat (as an agent) to OTRS.
- by DM a bot, agent can get a list of their ticket, add note, etc.

		Used CPAN module :
		
		Encode qw(decode encode)
		Digest::MD5 qw(md5_hex)
		Date::Parse
		MIME::Base64()


1. Create outgoing webhook at RC

		- Event trigger: message sent
		- Enabled: true
		- Name: Bot Operation
		- Channel: @rocket.cat
		- Trigger words: help,mine,get,addnote  (the list of command)
		- URLs: http://SERVERNAME/otrs/nph-genericinterface.pl/Webservice/GenericTicketConnectorREST/TicketRC/?UserLogin=webservice&Password=123
		- Post as: @rocket.cat
		- Take note on the TOKEN
		**THIS SETTING INDICATES WHEN USER INTERACT WITH BOT @rocket.cat VIA PM, THEN EXECUTES POST REQUEST TO OTRS WS** 

2. As per url, its point to /TicketRC/ connector with user and password assign to them. webservice user should at least have ro and note permission.

3. In OTRS, Go to Webservice (REST), Add operation RocketChat::TicketRC

		Name: TicketRC

4. Configure REST Network Trasnport

		*Route mapping for Operation 'TicketRC': /TicketRC/
		*Method: POST


5. Update System Configuration > GenericInterface::Operation::TicketRC###UsernameField

		Field name that hold the Rocket Chat agent username. Default: UserRCUsername


6. Update System Configuration > GenericInterface::Operation::TicketRC###Token

		Update the token (get from no 1).


7. Make sure OTRS agent has a RC username under their profile ( UserRCUsername )


8. Based on connector, otrs will listen to <command>/<ticketnumber> from rocket chat.

		example to get ticket details: get/1100068


Rules check

		- RocketChat token must be same with token registered in OTRS  
		- RockeChat user account name must be registered in the OTRS agent profile.


[![Capture.png](https://i.postimg.cc/5tZBMsdp/Capture.png)](https://postimg.cc/DWPJrdzb)  

[![Capture2.png](https://i.postimg.cc/k4hM6pwP/Capture2.png)](https://postimg.cc/1nw1bMLv) 

[![Capture3.png](https://i.postimg.cc/V6njsXzw/Capture3.png)](https://postimg.cc/zbDL0bL2)  

[![Capture4.png](https://i.postimg.cc/kGCW2D5b/Capture4.png)](https://postimg.cc/CBvRthkh)  



