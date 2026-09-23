--[[pod_format="raw",created="2026-08-31 10:12:09",modified="2026-08-31 10:12:09",revision=1]]
include("scorelib.lua")	
include("sidebar.lua")

scr = { w = 300, h = 168 }
gui = create_gui({x = 0, y = 0, width = scr.w, height = scr.h})
sidebar_width = 45
content_gap = 5
content_padding = 5
online_width = 55
current_room = nil
online_users = {}

function join_room(room_name)
	if current_room and current_room ~= room_name then
		local previous_room = current_room
		scoresub_set_table(previous_room)
		scoresub_send_system_packet("presence", "leave")
	end

	current_room = room_name
	chat_log = {}
	online_users = {}
	scoresub_set_table(room_name)
	scoresub_send_system_packet("presence", "join")
	if sidebar then
		sidebar.selected_room = room_name
	end
end

function resize_content()
	content_x = sidebar_width + content_gap + content_padding
	online_x = scr.w - online_width - content_padding
	content_width = max(1, online_x - content_gap - content_padding - content_x)
end

function handle_system_packet(packet)
	local system_type, action = scoresub_parse_system_packet(packet.extra)
	if not system_type then return false end
	if system_type ~= "presence" then return true end

	local user_id = packet.user_id or packet.username
	local previous = online_users[user_id]
	if not previous or packet.timestamp >= previous.timestamp then
		online_users[user_id] = {
			name = packet.username or tostring(user_id),
			timestamp = packet.timestamp,
			online = action == "join"
		}
	end
	return true
end

function draw_online_sidebar()
	local count = 0
	for _, user in pairs(online_users) do
		if user.online then count += 1 end
	end

	print("Online: "..count, online_x, 10, 7)
	local y = 22
	for _, user in pairs(online_users) do
		if user.online then
			print(user.name, online_x, y, 7)
			y += 10
		end
	end
end

-- on window resize event handler
-- msg is the message sent alongside the event (data about new window size)
on_event("resize", function(msg)
	-- update our global screen width and height
	scr.w = msg.width
	scr.h = msg.height
	resize_content()

	-- debug print the new window resolution
	--add(chat_log, {name = "debug", text = "Resized to: "..scr.w.."x"..scr.h})
	
	-- call the resize function for all gui elements (gui.child)
	if sidebar and sidebar.resize then
		sidebar:resize()
	end

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

	resize_content()
	sidebar = init_sidebar(gui, join_room)
	sidebar:resize()
	
	-- create a text input field
	text_input = gui:attach_text_editor {
		x = 0, y = 0, width = content_width, height = 15,
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
			self.parent.x = content_x
			self.parent.width = content_width
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

	join_room("messenger_room_1")

	for el in all(gui.child) do
		if el.resize then
			el:resize()
		end
	end
end



function _draw() 
	cls()
	sidebar:draw()
	--print("Fetched scores: "..#chat_log)

	local start_y = 10
	local max_lines = 12
	local chat_x = content_x
	local chat_width = content_width
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
				if print(test, 0, -99) > chat_width then
					-- if doesnt fit we print the line 
					print(line, chat_x, start_y, 7)
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
			print(line, chat_x, start_y, 7)
		end
		-- go to the next line
		start_y += 11
	end

	gui:draw_all() 
	draw_online_sidebar()
end

function _update() 
	sidebar:update()
	gui:update_all() 

	scoresub_poll(true)

	-- fetch new messages
	while scoresub_packet_count() > 0 do
		local packet = scoresub_get_packet()
		if packet then
			local timestamp = packet.timestamp
			local message = packet.extra
			if timestamp and message then
				if not handle_system_packet(packet) then
					local name = packet.username
					add(chat_log, {name = name, text = message})
				end
			end
		end
	end
end

function _shutdown()
	if current_room then
		scoresub_set_table(current_room)
		scoresub_send_system_packet("presence", "leave")
	end
end
