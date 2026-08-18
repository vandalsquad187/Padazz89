#!/system/bin/sh
SRV=/storage/emulated/0/Android/data/com.qx.gamingroom/files/server
export CLASSPATH=$SRV/QXToolMain.jar
exec app_process64 /storage/emulated/0/Android/data/com.qx.gamingroom/files/server com.qxtool.QXToolMain /storage/emulated/0/Android/data/com.qx.gamingroom/files com.qx.gamingroom 5 >> $SRV/c.txt 2>&1
