-----
-- User configuration file for lsyncd.
-- This needs lsyncd >= 2.0.3
--
-- This configuration's objective is to handle offline modifications
-- It will write a file on the drive when a file is ready for upload to the remote server
-- and will delete it when the file is successfully uploaded
-- If the computer is shutdown or the process crashes whitout finishing it's initial 
-- upload, on lsync startup, the file will be read and upload will retart.

--require "helenasync_runner"

sync{
    --offline_rsyncssh, 
    default.rsyncssh,
    source="/home/fullbright/scripts/", 
    host="sergio@home.afanou.com", 
    targetdir="/media/DATA/SERGIO-PC/sergio/syncwin/", 
    rsyncOpts="-ltusravC",
    statusFile="/tmp/lsyncd.status"

}

sync{
     default.rsyncssh, 
     source="/home/fullbright/mydropbox/", 
     host="sergio@home.afanou.com", 
     targetdir="/home/sergio/mydropbox/", 
     rsyncOpts="-ltusravC", 
     init=false
}

sync{default.rsyncssh, source="/home/fullbright/Documents/Personnel/documents/", host="sergio@home.afanou.com", targetdir="/media/DATA/SERGIO-PC/sergio/documents/", rsyncOpts="-ltusravC", init=false}

sync{default.rsyncssh, source="/home/fullbright/Documents/Professionnel/", host="sergio@home.afanou.com", targetdir="/media/DATA/SERGIO-PC/Professionel/", rsyncOpts="-ltusravC", init=false}
