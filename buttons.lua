function _init()
	window{width=85,height=120,title="Calculator",resizeable=false}
	testGui = create_gui()
	
	local room1 = {
		x=2, y=40, width=40, height=18, label="room 1",
			click=function()
			end
	}
	
	testGui:attach_button(room1)