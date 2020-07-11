Config                       = {}
Config.Locale 				 = 'en'

--EĞER LOGLARINZIN WEBHOOK İLE DİSCORDDA GÖZÜKMESİNİ İSTİYORSANIZ TRUE YAPIN. SQL ISTIYORSANIZ FALSE YAPIN. EĞER FALSE YAPACAKSANIZ KLASÖRÜN İÇİNDEKİ SQLİ OKUTMAYI UNUTMAYIN
Config.Discord 				 = true

SystemAvatar                 = 'https://wiki.fivem.net/w/images/d/db/FiveM-Wiki.png' --SISTEM LOGLLARININ AVATARI
UserAvatar 					 = 'https://i.imgur.com/KIcqSYs.png' --EĞER STEAM AVATAR RESMI YOKSA GOZUKUCEK AVATAR
SystemName 					 = 'CYLEX' 

Config.SistemLogu 			 = 'WEBHOOK_LINK_HERE'
Config.OldurmeLoglari		 = 'WEBHOOK_LINK_HERE'
Config.ChatLogu 			 = 'WEBHOOK_LINK_HERE'

Config.ItemVermeLogu     	 = "WEBHOOK_LINK_HERE"
Config.ItemAtmaLogu     	 = "WEBHOOK_LINK_HERE"

Config.ParaAtmaLogu   	     = "WEBHOOK_LINK_HERE"
Config.ParaVermeLogu         = "WEBHOOK_LINK_HERE"

Config.BankaParaVerme   	 = "WEBHOOK_LINK_HERE"
Config.SilahVermeLogu    	 = "WEBHOOK_LINK_HERE"
Config.SilahAtmaLogu         = "WEBHOOK_LINK_HERE"

Config.MermiliSilahAtmaLogu  = "WEBHOOK_LINK_HERE"
Config.MermiliSilahVermeLogu = "WEBHOOK_LINK_HERE"

Config.webhookadmin    	     = "WEBHOOK_LINK_HERE"
Config.webhookambulance      = "WEBHOOK_LINK_HERE"
Config.webhookmecano         = "WEBHOOK_LINK_HERE"
Config.webhookpolice         = "WEBHOOK_LINK_HERE"
Config.webhooktaxi           = "WEBHOOK_LINK_HERE"

-- İSTEMEDİĞİNİZ LOGLARI FALSE YAPARAK KAPATABILIRSINIZ.
Config.ItemVerme             = true
Config.EsyaAtma 		 	 = true
Config.ParaTransfer 	     = true
Config.ParaAtma 			 = true
Config.BankaParaTransfer     = true
Config.SilahVerme            = true
Config.MermiliSilahAtma      = true
Config.SilahAtma  		     = true
Config.MermiliSilahVerme     = true

SpecialCommands = {
				   --{'/ooc', '**[OOC]:**'},
				   --{'/911', '**[911]: (CALLER ID: [ USERNAME_NEEDED_HERE | USERID_NEEDED_HERE ])**'},
				   {'/report', '**[RAPOR]: [ USERNAME_NEEDED_HERE | USERID_NEEDED_HERE ] :**'},
				  }

						
-- Bu komutllar blackliste alınacaktır. Discordda gözükmeyecektir
BlacklistedCommands = {
					   --'/KOMUT1',
					  -- '/KOMUT2',
					  }

-- Ayrıyetten bir komuta webhook eklemek istiyorsanız:
OwnWebhookCommands = {
					  --{'/FARKLIKOMUT', 'WEBHOOK_LINK_HERE'},
					  --{'/FARKLIKOMUT2', 'WEBHOOK_LINK_HERE'},
					 }

-- TTS Mesajları
TTSCommands = {
			   --'/bos',
			   --'/bos2',
			  }
