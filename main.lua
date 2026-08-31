--[[pod_format="raw",created="2026-08-31 10:12:09",modified="2026-08-31 10:12:09",revision=1]]

function _init()
	scr = { w = 160, h = 168 }
	window(scr.w, scr.h, {resizable = true, pauseable = false})
	
	gui = create_gui({x = 0, y = 0, width = scr.w, height = scr.h})

	text_input = gui:attach_text_editor {
		x = 5, y = 145, width = 150, height = 15,
		key_callback = {
			enter = function(self)
				local lines = self:get_text()
				if lines and lines and #lines > 0 then
					scoresub("global_chat", 0, lines)
					self:set_text("")
				end
			end
		}
	}
	
	chat_log = {}
	last_fetch = 0
	fetch_interval = 30 
end

function _draw() 
	cls(1)
	
	local start_y = 10
	local max_lines = 12
	local start_index = max(1, #chat_log - max_lines + 1)
	
	for i = start_index, #chat_log do
		local msg = chat_log[i]
		print(msg.name..": "..msg.text, 5, start_y, 7)
		start_y += 11
	end

	gui:draw_all() 
end

function _update() 
	gui:update_all() 
	
	last_fetch += 1
	if last_fetch >= fetch_interval then
		last_fetch = 0
		
		local scores = scoresub("global_chat")
		if scores then
			chat_log = {}
			for i = 1, #scores do
				if scores[i].extra and #scores[i].extra > 0 then
					add(chat_log, {
						name = scores[i].username or "anon",
						text = scores[i].extra
					})
				end
			end
		end
	end
end
