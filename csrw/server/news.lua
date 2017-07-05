if true then
	return
end
if hasObjectPermissionTo(getThisResource(), "function.fetchRemote") then
	function onNewsDownloaded(data, errno)
		if errno == 0 then
			local newsFile = fileCreate("news")
			fileWrite(newsFile, data)
			fileClose(newsFile)
		else
			outputServerLog("ERROR: Can't download news (error " .. errno .. ").")
		end
	end
	fetchRemote("http://redknife.tk/csrw/update/news.xml", onNewsDownloaded)
end