---
---
---
---

tattleMove = {
    onMove = function(oEvent, dEvent)
        log("TattleMove", "A moved happened from ",oEvent.pathname," to ",dEvent.pathname)
    end,
}

offline_rsyncssh = {
    -- based on default rsync.
	default.rsyncssh,
	
	-- for this config it is important to keep maxProcesses at 1, so
	-- the postcmds will only be spawned after the rsync completed
	maxProcesses = 1,
	
	--onStartup = function(inlet)
	    --- Load offline actions and sync
	    ---log("Offline","--- Loading offline actions")
	    ---spawn(event, "/home/fullbright/.helenasync/lipsync-notify", 
		---			"Offline ...", "Loading offline files.")

	    ---log("Offline","--- Adding offline actions to sync queue")
	    ---will stack on the queue and do the postcmd when its finished
	    ---local offline_event = inlet.createBlanketEvent()
	    ---offline_event.isOffline = true
	    -- the original event is simply forwarded to the normal action handler
	    ---return default.rsync.action(inlet)
	---end,
	
	-- called whenever something is to be done
	action = function(inlet)
	    log("Offline","Entering inlet function")
		local event = inlet.getEvent()
		local config = inlet.getConfig()
		
		log("Offline", "Event type : ", event.etype)
		log("Offline", "Config source : ", config.source)
		log("Offline", "Config target : ", config.target)
		log("Offline", "Event source : ", event.source)
		log("Offline", "Event target : ", event.target)
		log("Offline", "Event path : ", event.path)
		log("Offline", "Event pathname : ", event.pathname)
		log("Offline", "Event sourcepath : ", event.sourcePath)

		-- if the event is a blanket event and not the startup,
		-- its there to spawn the webservice restart at the target.
		-- if event.etype == "Blanket" then
			-- uses rawget to test if "isPostcmd" has been set without
			-- triggering an error if not.
			-- local isPostcmd = rawget(event, "isPostcmd")
			
			-- if event.isPostcmd then
				-- return offline_rsyncssh.storefile(inlet)
				-- OfflineAgent.storefile(inlet)
				-- return
			-- else
            			-- this is the startup, forwards it to default routine.
            			-- return default.rsyncssh.action(inlet) 
			-- end
			-- error("this should never be reached")	
		-- end
		-- for any other event, a blanket event is created that
		-- will stack on the queue and do the postcmd when its finished
		-- local sync = inlet.createBlanketEvent()
		-- sync.isPostcmd = true
		-- sync.isOffline = true
		-- the original event is simply forwarded to the normal action handler
		return default.rsync.action(inlet)
	end,

	-- called when a process exited.
	-- this can be a rsync command, the startup rsync or the postcmd
	collect = function(agent, exitcode)
		-- for the ssh commands 255 is network error -> try again
		--local isPostcmd = rawget(agent, "isPostcmd")
		-- local isOffline = rawget(agent, "isOffline")
		-- if not agent.isList and agent.etype == "Blanket" and isOffline then
			---if exitcode == 255 then
				---spawn(event, "/home/fullbright/.helenasync/lipsync-notify", 
					---" Offline - Again", "Network error again")
				---return "again"
			---else
				---spawn(event, "/home/fullbright/.helenasync/lipsync-notify", 
					---" Done", "Ok")
				---return
			---end
		---else
			--- everything else, forward to default collection handler
			---return default.collect(agent,exitcode)
		---end
		---error("this should never be reached")
		log("Offline", "Collecting exiting process")
		log("Offline", "Agent : ", tostring(agent))
		log("Offline", "Agent exit code : ", exitcode)
		log("Offline", "Agent source path : ", agent.sourcePath)
		log("Offline", "Agent etype : ", agent.etype)
		
		log("Offline", "Deleting offline file : ")

		log("Offline", "Done.")
		--return default.collect(agent,exitcode)
		return
	end,

	-- called before anything else
	-- builds the target from host and targetdir
	prepare = function(config)
		if not config.host then
			error("offline_rsyncssh needs 'host' configured", 4)
		end
		if not config.targetdir then
			error("offline_rsyncssh needs 'targetdir' configured", 4)
		end
		if not config.target then
			config.target = config.host .. ":" .. config.targetdir
		end

		log("Offline", "Loading all offline files")
		log("Offline", "Creating blanklet event to queue")
		log("Offline", "Done")

		return default.rsync.prepare(config)
	end,


	storefile = function(inlet)
		log("Offline","--------- Writing offline file to disk ...")
		---io.output(io.open("/home/fullbright/.helenasync/offline/lipsync.offline","w"))
		---io.write("This is\nsome sample text\nfor Lua.")
		---io.close()
		
		local event = inlet.getEvent()
		local config = inlet.getConfig()
		local rdseed = math.randomseed(os.time())
		local file = assert(io.open("/home/fullbright/.helenasync/offline/lipsync.offline"..rdseed, "w"))
		spawn(event, "/opt/helenasync/bin/lipsync-notify", 
			"Syncing ...", "/opt/helenasync/conf/offline/lipsync.offline."..rdseed)
		local content = ""

		--- etype				
		if(event.etype == nil) then
			log("Offline","---- No event etype defined.")
		else
			content = content.."event.etype="..event.etype.."\n"
		end

		--- path				
		if(event.path == nil) then
			log("Offline","---- No event path defined.")
		else
			content = content.."event.path="..event.path.."\n"
		end

		--- source				
		if(event.source == nil) then
			log("Offline","---- No event source defined.")
		else
			content = content.."event.source="..event.source.."\n"
		end

		--- source path				
		if(event.sourcePath ~= nil) then
			content = content.."event.sourcePath="..event.sourcePath.."\n"
		end

		file:write(content)
		file:close()

		log("Offline", "Storing offline file path in the event")
		event.offlinefile = "/opt/helenasync/conf/offline/lipsync.offline"..rdseed
		log("Offline","--------- Offline file written.")
		return
	end

}
