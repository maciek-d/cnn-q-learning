
DYING_STATE = 11
player = 1 -- 2 for luigi
loop_indicator_file = "loop_screenshot.dat"
screenshot_count = 0

function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end


function getPositions()
        marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
        marioY = memory.readbyte(0x03B8)+16
        mariostate = memory.readbyte(0x0E) --get mario's state. (entering exiting pipes, dying, picking up a mushroom etc etc)
		yspeed = memory.readbyte(0x009F) --y velocity 1-5 are falling and 250-255 is jumping
		
		x_direction = memory.readbyte(0x0057) --if this number is over 200 we are going backwards
		xspeed = memory.readbyte(0x0700) -- 0 to 48
		
		
		if yspeed >=1 and yspeed <10 then
			falling = true
		else
			falling = false
		end
		if yspeed >= 250 and yspeed <= 255 then
			jumping = true
		else 
			jumping = false
		end
        currentscreen = memory.readbyte(0x071A) --finds current screen for loop detection
        nextscreen = memory.readbyte(0x071B) --finds next screen
		
		CurrentWorld = memory.readbyte(0x075F) --finds the current world (value + 1 is world)
		CurrentLevel = memory.readbyte(0x0760) --finds the current level (0=1 2=2 3=3 4=4)
		demoruncheck = memory.readbyte(0x0770) --equals 0 for demo and 1 for normal run
		statuscheck = memory.readbyte(0x0772) -- 3= playing 1 = loading
       
        screenX = memory.readbyte(0x03AD)
        screenY = memory.readbyte(0x03B8)
		
		x_offset = memory.readbyte(0x071C)
		-- +2 back of mario +14 front of mario
		rel_marioX = marioX  - x_offset  - (255* currentscreen) - currentscreen + 2
		rel_marioX_front =  marioX  - x_offset  - (255* currentscreen) - currentscreen + 14
end

function marioFunction()
	getPositions()
	mariohole = false
	if marioY + 65 + memory.readbyte(0xB5)*255 > 512 then --added the fallen into a hole variable that will activate when mario goes below screen
        mariohole = true
    end
	score = marioX + math.floor((192-marioY)/30)
	if mariohole or mariostate == DYING_STATE then
		score = -1
	end
	f = io.open("score.dat", "w")
	f:write(score)
	io.close(f)
end




function wait_for_screenshot()
	screenshot_file = "screenshot" .. tostring(screenshot_count) .. ".dat"
	f = io.open(screenshot_file, "w")
	if f then 
		io.close(f)
	else 
		wait_for_screenshot()
	end
	while file_exists(screenshot_file) do
	end
	screenshot_count = screenshot_count + 1
end


function createLoopIndicatorFile()
	f = io.open(loop_indicator_file, "w")
	if f then 
		io.close(f)
	else 
		createLoopIndicatorFile()
	end
end



world = 0
level = 3
transition = false
lastXPos = 0
marioWasJustOnGround = false
pressedUpLast = false
load_death_state = 3


function marioFinishedLevel() -- todo this function needs to be adjusted as we beat new levels 
	getPositions()
	if CurrentLevel > level then
		transition = false
		level = level + 1 
		load_death_state = load_death_state + 1
		return false
	elseif CurrentWorld > world then
		transition = false
		world = world + 1 
		level = 1
		load_death_state = load_death_state + 1
		return false
	end 
	if marioX > 3160 or transition then
		transition = true
		return true
	end
-- check for levels that end on different marioX values
--	if CurrentWorld == 0 then 
--		if CurrentLevel == 1 then 
-- 4-1 is 3593?
	return false
end




-- always load savestate 1 at the beggining of the run
-- or 2 if after crash
savestate.load(savestate.object(load_death_state))

max_mario_x = 40
no_progress_iteration = 0 
getPositions()

loop_iteration = 0
resetJump = false

ButtonNames = {
	"A",
	"B",
	"up",
	"down",
	"left",
	"right",
}
n_outputs = #ButtonNames 
button_file = "lua_data.dat"
choice_flag = "choice_done"
exit_file = "exit"

function getTile(dx, dy)
        local x = marioX + dx + 8
        local y = marioY + dy - 16
        local page = math.floor(x/256)%2
 
        local subx = math.floor((x%256)/16)
        local suby = math.floor((y - 32)/16)
        local addr = 0x500 + page*13*16+suby*16+subx
       
        if suby >= 13 or suby < 0 then
            return 0
        end
       
        if memory.readbyte(addr) ~= 0 then
            return 1
        else
            return 0
        end
end

function preventJumpWhenFalling() -- prevents jump to be pressed if about to fall on tile
	getPositions()
	if resetJump == true then -- will make mario jump on next possible frame without waiting for the next input  
		resetJump = false     -- this can help with some edge cases where mario has to jump quickly, it also makes jumps more consistent 
		outputs[ButtonNames[1]] = true
	end
	if pressedUpLast and marioWasJustOnGround then
		if getTile(0,33) == 1 then -- if mario is still standing on the ground 
			outputs[ButtonNames[1]] = false -- if mario tied to jump but is still on the ground set jump to false so he can jump on next try
			resetJump = true
		end
	end 
	if falling then 
		outputs[ButtonNames[1]] = false
	end
	
	lastXPos = marioX
	if outputs[ButtonNames[1]] == true then
		pressedUpLast = true
	else 
		pressedUpLast = false
	end
	if getTile(0,33) == 1 then  -- checks if mario is standing on the ground
		marioWasJustOnGround = true
	else 
		marioWasJustOnGround = false
	end
end

block_dim = 16
function certainFallDeath()
	getPositions()
	
	
	local max_y = 232
	local marioY_bottom = marioY + 8
	local slope = .5
	
	no_tile = true
	if marioY > 250 then -- todo make else block here dont be lz
			no_tile = false
			
	end -- dont tell me what todo comment above
	-- well the dream was given up on pretty early on and the code is inneficient now
	for y=marioY_bottom+8, max_y + 1, block_dim/2 do
		y_height = math.floor(max_y - marioY_bottom)
		current_dy = y - marioY_bottom 
		slope = xspeed/100 -- set slope accoding to speed
		if xspeed == 0 then -- check only directly below mario to see if he is dead
			x_spacing = 4
			check_distance = rel_marioX + 8
		elseif current_dy <= 10 then
			x_spacing = block_dim 
			check_distance = rel_marioX_front + slope*current_dy 
		elseif current_dy <= 64 then
			x_spacing = block_dim 
			check_distance = rel_marioX_front + slope*current_dy + 10
		else
			x_spacing = block_dim 
			check_distance = rel_marioX + 40  
		end
		
		for x=rel_marioX, check_distance, x_spacing do 
			--print(x, ' ', y, ' tile?', getTile(x-rel_marioX, y-marioY))
			
			if getTile(x-rel_marioX, y-marioY) == 1 then
				no_tile = false
				
				break
			end
		end
		if not no_tile then
			break
		end
	end
	print(no_tile)
	return no_tile
end

while (true) do
	
	
	--screenshot_file = '.\snaps\Super Mario Bros (E)-0.png'
	--while file_exists(screenshot_file) do
	--end
	
	-- check for memory cap ... so the program doesnt crash
	wait_for_screenshot()
	

	
	if mariostate == DYING_STATE or mariohole then
		marioFunction()
		createLoopIndicatorFile()
		for i = 0, 25 do -- choose a number that aligns screenshots so the input doesnt get misaligned
			emu.frameadvance();
			wait_for_screenshot()
		end
		while screenshot_count % 5 ~= 0 do
			emu.frameadvance();
			wait_for_screenshot()
		end
		while file_exists(loop_indicator_file) do --make sure to remove the file 
			os.remove(loop_indicator_file)
		end
		
		savestate.load(savestate.object(load_death_state))
		no_progress_iteration = 0
		max_mario_x = 40
	end
	while not file_exists(button_file) do
		if file_exists(exit_file) then --this pairs with the python script so lua doesnt freeze when ai is terminated
			os.remove(exit_file) -- exit file communicates termination it needs to be deleted before lua runs again  
			do return end -- exits lua script, os.exit() will exit the whole emulator
		end
	end
	button_choice = 6
	if file_exists(button_file) then
		f = io.open(button_file, "r")
		button_choice = tonumber(f:read "*a")
		io.close(f)
		while button_choice == nil do
			f = io.open(button_file, "r")
			button_choice = tonumber(f:read "*a")
			io.close(f)
		end
		--print(button_choice)
		os.remove(button_file)
	end
	

	
	-- additional choices AB rightAB leftAB rightB leftB .. rightA leftA 
	
	
	outputs = {}
	
	if button_choice == 2 then
		button_choice = 5
	elseif button_choice == 3 then
		button_choice = 6
	end 
		
	for i=1, n_outputs do
		button = ButtonNames[i]
		if i == button_choice then 
			outputs[button] = true
		else
			outputs[button] = false
		end
	end 
	-- pernamently press B
	button = ButtonNames[2]
	outputs[button] = true

	if outputs[ButtonNames[6]] == true then
		suffix_text = ' >>> '
	elseif outputs[ButtonNames[1]] == true then
		suffix_text = ' ^^^ >>> '
		outputs[ButtonNames[6]] = true
	elseif outputs[ButtonNames[5]] == true then
		suffix_text = ' <<< '
	else
		suffix_text = ''
	end
	-- Remove this once you introduce lstm, this makes it so mario stops pressing jump before landing
	
	print(suffix_text, button_choice )
	---- 34123
	--preventJumpWhenFalling() 
	joypad.set(player, outputs)
	emu.frameadvance();
	preventJumpWhenFalling()
	wait_for_screenshot()
	joypad.set(player, outputs)
	emu.frameadvance();
	preventJumpWhenFalling()
	wait_for_screenshot()
	joypad.set(player, outputs)
	emu.frameadvance();
	preventJumpWhenFalling()
	wait_for_screenshot()
	joypad.set(player, outputs)
	emu.frameadvance();
	preventJumpWhenFalling()
	wait_for_screenshot()
	joypad.set(player, outputs)
	emu.frameadvance();
	preventJumpWhenFalling()
	
	--getPositions()
	if falling then -- check if death is certain when falling
		fall_death = certainFallDeath()
		if fall_death then
			print("Certain fall death")
			score = -1
			marioFunction()
			createLoopIndicatorFile()
			while falling do
				getPositions()
				if marioY > 242 then
					while file_exists(loop_indicator_file) do --make sure to remove the file 
						os.remove(loop_indicator_file)
					end
					print("Breaking out of falling loop")
					break
				end
				wait_for_screenshot()
				emu.frameadvance();
				
			end	
			score = 0
		end 
	end
	
	marioFunction()
	
	if max_mario_x < marioX then
		no_progress_iteration = 0
		max_mario_x = marioX
	else
		no_progress_iteration = no_progress_iteration + 1
	end
	
	statuscheck = memory.readbyte(0x0772)
	if statuscheck == 1 or marioFinishedLevel() then
		createLoopIndicatorFile()
	end
	
	while statuscheck == 1 or marioFinishedLevel() do -- game is loading or mario cannot move
		statuscheck = memory.readbyte(0x0772) -- 3= playing 1 = loading
		emu.frameadvance();
		wait_for_screenshot()
	end
	while file_exists(loop_indicator_file) do --make sure to remove the file 
		-- align screenshots here making sure that the screenshot value is divisible by 4 before continuing
		while (screenshot_count + 1) % 5 ~= 0 do
			wait_for_screenshot()
		end
		os.remove(loop_indicator_file)
		no_progress_iteration = 0
	end
	
	if no_progress_iteration >= 300 and mariostate ~= DYING_STATE and not mariohole then
		savestate.load(savestate.object(load_death_state))
		no_progress_iteration = 0
		max_mario_x = 40
	end

	loop_iteration = loop_iteration + 1
	
end;