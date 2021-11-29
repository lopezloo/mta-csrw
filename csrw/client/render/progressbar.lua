local progress = {
	name = "",
	count = 0,
	countX = 0,
	updateCount = 0,
	direction = false,
	timer = nil,

	draw = { -- 1680x1050
		background = {0.22083333333*sX, 0.43142857142*sY, 0.55833333333*sX, 0.03333333333*sY}, -- 371, 453, 938, 35
		main = {0.22559523809*sX, 0.43809523809*sY, 0.54761904761*sX, 0.02*sY} -- 379, 460, 920, 21
	}	
}

addEvent("onProgressBarEnd")

function drawProgressBar()
    dxDrawRectangle(progress.draw.background[1], progress.draw.background[2], progress.draw.background[3], progress.draw.background[4], tocolor(0, 0, 0, 153), false) -- tlo
    dxDrawRectangle(progress.draw.main[1], progress.draw.main[2], progress.countX, progress.draw.main[4], tocolor(239, 97, 3, 196), false)
end

function setProgressBar(progressName, updateCount, theDirection)
	-- theDirection = false = w prawo | theDirection = true = w lewo

	progress.name = progressName
	progress.direction = theDirection
	if not theDirection then
		progress.count = 0
		progress.countX = 0
	else
		-- pełny pasek
		progress.count = 1
		progress.countX = progress.draw.main[3]
	end
	progress.updateCount = updateCount -- wartość update co 50ms
	progress.timer = setTimer(updateProgress, 50, 1)
	addEventHandler("onClientRender", root, drawProgressBar)
end

function stopProgressBar()
	if isTimer(progress.timer) then
		killTimer(progress.timer)
	end
	removeEventHandler("onClientRender", root, drawProgressBar)
	progress.name = ""
end

function updateProgress()
	if not progress.direction then
		-- w prawo
		progress.count = progress.count + progress.updateCount
		if progress.count >= 1 then
			progress.count = 1
			triggerEvent("onProgressBarEnd", resourceRoot, progress.name)
			stopProgressBar()
		else
			progress.timer = setTimer(updateProgress, 50, 1)
		end
	else
		-- w lewo
		progress.count = progress.count - progress.updateCount
		if progress.count <= 0 then
			progress.count = 0
			triggerEvent("onProgressBarEnd", resourceRoot, progress.name)
			stopProgressBar()
		else
			progress.timer = setTimer(updateProgress, 50, 1)
		end		
	end
	progress.countX = progress.draw.main[3] * progress.count

end

function getCurrentProgressBar()
	return progress.name
end
