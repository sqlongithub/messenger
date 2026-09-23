--[[pod_format="raw",created="2026-08-31 10:12:09",modified="2026-08-31 10:12:09",revision=1]]
include("scorelib.lua")	
include("sidebar.lua")

scr = { w = 160, h = 168 }
gui = create_gui({x = 0, y = 0, width = scr.w, height = scr.h})

-- on window resize event handler
-- msg is the message sent alongside the event (data about new window size)
on_event("resize", function(msg)
	-- update our global screen width and height
	scr.w = msg.width
	scr.h = msg.height

	-- debug print the new window resolution
	--add(chat_log, {name = "debug", text = "Resized to: "..scr.w.."x"..scr.h})
	
	-- call the resize function for all gui elements (gui.child)
	for el in all(gui.child) do
		if el.resize then
			el:resize()
		elseif el.child[1].resize then
			el.child[1]:resize()
		end
	end
end)

function _init()

	-- create a window
	window(scr.w, scr.h, {resizable = true, pauseable = false})
	
	-- create a text input field
	text_input = gui:attach_text_editor {
		x = 10, y = scr.h - 10, width= 100, height = 15,
		key_callback = {
			enter = function(self)
				-- submit the message packet with the first line of the text editor
				scoresub_send_packet(self:get_text()[1])
				--add(chat_log, {name = stat(65), text = self:get_text()[1]})
				-- reset the text inside the input field
				self:set_text("")

			end
		},
		resize = function(self)
			--add(chat_log, {name = "debug", text = "text_input update"})
			self.parent.width = scr.w - 10
			self.width = self.parent.width
			self.parent.y = scr.h - self.height - 5
			self.y = 0
		end
	}

	-- chat_log is a table containing all messages 
	-- each message is a table containing:
	--   .text 
	--   .name
	--   (.timestamp)
	chat_log = {}
	last_fetch = 0
	fetch_interval = 30 

	--init_sidebar(gui)
	sidebar = gui:attach {
        x = 5, y = 5, width = 50, height = scr.h - 10,

        draw = function(self)
			local parent = self.parent
			local grandparent = parent and parent.parent
			print("sidebar: "..self.x..","..self.y, 60, 10, 7)
			print("parent: "..(parent and parent.x or "nil")..","..(parent and parent.y or "nil"), 60, 20, 7)
			print("grandparent: "..(grandparent and grandparent.x or "nil")..","..(grandparent and grandparent.y or "nil"), 60, 30, 7)
        end, 

        resize = function(self)
			self.x = 5
			self.y = 5
            self.height = scr.h - 10
        end
    }

	scoresub_set_table("messenger_room_1")

	for el in all(gui.child) do
		if el.resize then
			el:resize()
		end
	end
end



function _draw() 
	cls()
	rectfill(5, 5, 55, scr.h - 5, 4)
	--print("Fetched scores: "..#chat_log)

	local start_y = 10
	local max_lines = 12
	local max_y = scr.h - 25
	local start_index = max(1, #chat_log - max_lines + 1)
	
	-- for each message in the chat log
	for i = start_index, #chat_log do
		-- if we are past the bottom of the screen then dont print anymore
		if start_y > max_y then break end
		local msg = chat_log[i]
		local text = type(msg.text) == "table" and msg.text[1] or msg.text

		-- initialize the line "user: "
		local line = msg.name..": "
		
		-- for each word in the text (%S+ splits on space)
		for word in text:gmatch("%S+") do
			-- j is the index of the current char in the word
			for j = 1, #word do
				-- test is the line with the current char appended
				-- print returns the width of the text printed text
				-- some characters are wider than others so we need to test it like this
				local test = line..word:sub(j, j)
				-- print outside the screen and check if the width is smaller than the screen width
				if print(test, 0, -99) > scr.w - 20 then
					-- if doesnt fit we print the line 
					print(line, 5, start_y, 7)
					-- go to the next line
					start_y += 11
					-- start a new line with the current char which didnt fit
					line = word:sub(j, j)
				else
					-- if it fits the line is just the entire word (and all the previous words up to this point)
					line = test
				end
			end
			-- keep appending words to the line
			line = line.." "
		end
		if start_y <= max_y then
			-- print the line if we are still within the screen height
			print(line, 5, start_y, 7)
		end
		-- go to the next line
		start_y += 11
	end

	gui:draw_all() 
end

function _update() 
	gui:update_all() 

	scoresub_poll(true)

	-- fetch new messages
	while scoresub_packet_count() > 0 do
		local packet = scoresub_get_packet()
		if packet then
			local timestamp = packet.timestamp
			local message = packet.extra
		--	add(chat_log, {name = "debug", text = "packet recieved"})
			if timestamp and message then
				local name = packet.username
				add(chat_log, {name = name, text = message})
			end
		end
	end
end
