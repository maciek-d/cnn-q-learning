function getPositions() 
        marioX = memory.readbyte(0x6D) * 0x100 + memory.readbyte(0x86)
        marioY = memory.readbyte(0x03B8)+16
        mariostate = memory.readbyte(0x0E) --get mario's state. (entering exiting pipes, dying, picking up a mushroom etc etc)
		yspeed = memory.readbyte(0x009F) --y velocity 1-5 are falling and 250-255 is jumping
		-- xspeed 0057 0700
		x_direction = memory.readbyte(0x0057) --if this number is over 200 we are going backwards
		xspeed = memory.readbyte(0x0700) -- 0 to 48 
		if yspeed >1 and yspeed <10 then
			falling = true
		else
			falling = false
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

player = 1
block_dim = 16
function certainFallDeath()
	getPositions()
	local max_y = 232
	local marioY_bottom = marioY + 8
	local slope = .5
	
	color = 0x88880000
	tile_detected = true
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
				tile_detected = false
				break
			end
			
			gui.rect(x,   y, x+3,   y+3, toRGBA(color))
		end
		if not tile_detected then
			break
		end
	end
	return tile_detected
end
ButtonNames = {
        "A",
        "B",
        "up",
        "down",
        "left",
        "right",
    }
--memory.writebyte(0x0E, (9+256) )

function toRGBA(ARGB)
	return bit.lshift(ARGB, 8) + bit.rshift(ARGB, 24)
end

while true do
	getPositions()
	pressed = joypad.get(player)
	
	outputs = {}
	for i=1,#ButtonNames do
		if pressed[i] == true then
			outputs[i] = true
		else
			outputs[i] = false
		end
	end
	--- (marioX%80)
	-- 071C, 073F
	
	
		--print(marioY)
	
	color = 0x88880000
	height = 4
	final_y = marioY + height*16
	slope = .5 * height*16
	
	--gui.rect(0,0, 232, 232, toRGBA(color))
	first_fall = true 
	second_fall = true
	falling_iter = 0
	while falling do
		getPositions()
		
		if first_fall then 
			fall_starty = marioY
			getPositions()
			
			dead = certainFallDeath()
			
			if marioY > 250 then
				dead = false
			else 
				print(dead)
				first_fall = false
			end
			gui.line(rel_marioX_front,   marioY+8, rel_marioX_front+slope,   final_y , toRGBA(color))
			gui.line(rel_marioX_front+1, marioY+8, rel_marioX_front+slope+1, final_y , toRGBA(color))
			gui.line(rel_marioX_front+2, marioY+8, rel_marioX_front+slope+2, final_y , toRGBA(color))
			gui.line(rel_marioX_front+slope  , final_y, rel_marioX_front+slope  , final_y +200, toRGBA(color))
			gui.line(rel_marioX_front+slope+1, final_y, rel_marioX_front+slope+1, final_y +200, toRGBA(color))
			gui.line(rel_marioX_front+slope+2, final_y, rel_marioX_front+slope+2, final_y +200, toRGBA(color))
		end 
		
		
		dead = certainFallDeath()
		if marioY > 250 then
			dead = false
		end
		if dead then
			print('dead')
		end
		falling_iter = falling_iter + 1
		pressed = joypad.get(player)
		outputs = {}
		for i=1,#ButtonNames do
			if pressed[i] == true then
				outputs[i] = true
			else
				outputs[i] = false
			end
		end
	--		for i=1,#ButtonNames do
	--		outputs[i] = false
		--end
		--print(marioX , ' ', marioY, ' dy ', yspeed)

		joypad.set(player, outputs)
		--emu.pause()
		emu.frameadvance()		
	end
	 --print(currentscreen)
	
	
	joypad.set(player, outputs)
	emu.frameadvance()
	--marioX, ' ', marioY ,
	--print( 'dx ', xspeed, ' ', x_direction )
	
end




-- figure out number of blocks to the ground (plus one)
-- every Oneblock you can go down you go 2 blocks across if xspeed is 48
-- check that layer then check the next layer etc etc. (with margin of error of 1 block back 2 blocks max)

-- actually would be best to figure out the exact equation 