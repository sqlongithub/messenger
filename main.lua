--[[pod_format="raw",created="2026-08-31 10:12:09",modified="2026-08-31 10:12:09",revision=0]]

function _init()
	scoresub_init("messenger_room-1")

	
	scr = { w = 160, h = 168 }
	window(scr.w, scr.h, {resizable = true})
	
	gui = create_gui({x = 0, y = 0, width = scr.w, height = scr.h})

	text_input = gui:attach_text_editor {
		x = 5, y = 50, width = 150, height = 15,
		key_callback = {
			enter=function(self)
				scoresub(0, {text = self:get_text()[1]})
			end
		}
	}
end

function _draw() 
	cls()

	gui:draw_all() 
end

function _update() 
	gui:update_all() 
end
