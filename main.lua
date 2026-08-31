--[[pod_format="raw",created="2026-08-31 10:12:09",modified="2026-08-31 10:12:09",revision=0]]

function _init()
	scr = { w = 160, h = 168 }
	window(scr.w, scr.h, {resizable = true})
	
	gui = create_gui({x = 0, y = 0, width = scr.w, height = scr.h})
end

function _draw() 
	cls(1)
	gui:draw_all() 
end

function _update() 
	gui:update_all() 
end
