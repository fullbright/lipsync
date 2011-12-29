-----
-- User configuration file for lsyncd.
-- This needs lsyncd >= 2.0.3
--
-- This configuration's objective is to handle offline modifications
-- It will write a file on the drive when a file is ready for upload to the remote server
-- and will delete it when the file is successfully uploaded
-- If the computer is shutdown or the process crashes whitout finishing it's initial 
-- upload, on lsync startup, the file will be read and upload will retart.

local offline_rsyncssh = {
    -- based on default rsync.
	default.rsyncssh,
	
	-- for this config it is important to keep maxProcesses at 1, so
	-- the postcmds will only be spawned after the rsync completed
	maxProcesses = 1,
	
	-- called whenever something is to be done
	action = function(inlet)
	    log("Normal", " - - - - - - - >>>> Entering inlet function")
		local event = inlet.getEvent()
		local config = inlet.getConfig()
		-- if the event is a blanket event and not the startup,
		-- its there to spawn the webservice restart at the target.
		if event.etype == "Blanket" then
			-- uses rawget to test if "isPostcmd" has been set without
			-- triggering an error if not.
			local isPostcmd = rawget(event, "isPostcmd")
			if event.isPostcmd then
				spawn(event, "/home/fullbright/.helenasync/lipsync-notify", 
					"Syncing "..event.sourcePathname)
        		return
			else
            	-- this is the startup, forwards it to default routine.
            	return default.rsyncssh.action(inlet) 
        	end
			error("this should never be reached")
		end
		-- for any other event, a blanket event is created that
		-- will stack on the queue and do the postcmd when its finished
		local sync = inlet.createBlanketEvent()
		sync.isPostcmd = true
		-- the original event is simply forwarded to the normal action handler
		return default.rsync.action(inlet)
	end,

	-- called when a process exited.
	-- this can be a rsync command, the startup rsync or the postcmd
	collect = function(agent, exitcode)
		-- for the ssh commands 255 is network error -> try again
		local isPostcmd = rawget(agent, "isPostcmd")
		if not agent.isList and agent.etype == "Blanket" and isPostcmd then
			--if exitcode == 255 then
				--return "again"
			--end
			--return
			--spawn(agent, "/home/fullbright/.helenasync/lipsync-notify", 
			--		"Syncing "..agent.source.." done.", "")
			log("Offline", "Agent finished updating the file on the server.");
			return
		else
			--- everything else, forward to default collection handler
			return default.collect(agent,exitcode)
		end
		error("this should never be reached")
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
		return default.rsync.prepare(config)
	end
}

settings = {
   logfile    = "/home/fullbright/.helenasync/offline_test.log",
   statusFile = "/home/fullbright/.helenasync/offline_test.status",
   nodaemon   = true,
}

sync{
    offline_rsyncssh, 
    source="/home/fullbright/scripts/", 
    host="sergio@home.afanou.com", 
    targetdir="/media/DATA/SERGIO-PC/sergio/syncwin/", 
    rsyncOps="-ltusravC"
}
