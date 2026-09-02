--[[pod_format="raw",created="2026-08-31 10:12:09",modified="2026-08-31 10:12:09",revision=1]]
include("scorelib.lua")	

scr = { w = 160, h = 168 }
gui = create_gui({x = 0, y = 0, width = scr.w, height = scr.h})

on_event("resize", function(msg)
	scr.w = msg.width
	scr.h = msg.height

	--add(chat_log, {name = "debug", text = "Resized to: "..scr.w.."x"..scr.h})
	
	for el in all(gui.child) do
		if el.resize then
			el:resize()
		elseif el.child[1].resize then
			el.child[1]:resize()
		end
	end
end)

function _init()

	window(scr.w, scr.h, {resizable = true, pauseable = false})
	
	text_input = gui:attach_text_editor {
		x = 10, y = scr.h - 10, width= 100, height = 15,
		key_callback = {
			enter = function(self)
				scoresub_send_packet(self:get_text()[1])
				--add(chat_log, {name = stat(65), text = self:get_text()[1]})
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
	
	chat_log = {}
	last_fetch = 0
	fetch_interval = 30 

	scoresub_set_table("messenger_room_1")

	for el in all(gui.child) do
		if el.resize then
			el:resize()
		end
	end
end



function _draw() 
	cls()
	--print("Fetched scores: "..#chat_log)
	
	local start_y = 10
	local max_lines = 12
	local start_index = max(1, #chat_log - max_lines + 1)
	
	for i = start_index, #chat_log do
		local msg = chat_log[i]
		local text = type(msg.text) == "table" and msg.text[1] or msg.text
		local line = msg.name..": "
		
		for word in text:gmatch("%S+") do
			for j = 1, #word do
				local test = line..word:sub(j, j)
				if print(test, 0, -99) > scr.w - 20 then
					print(line, 5, start_y, 7)
					start_y += 11
					line = word:sub(j, j)
				else
					line = test
				end
			end
			line = line.." "
		end
		print(line, 5, start_y, 7)
		start_y += 11
	end

	gui:draw_all() 
end

function _update() 
	gui:update_all() 

	scoresub_poll(true)

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
