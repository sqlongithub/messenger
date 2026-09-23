function init_sidebar(gui, on_room_selected)
	local sidebar = {
		parent = gui,
		x = 5, y = 5, width = 45, height = scr.h - 10,
		buttons = {},
		mouse_down = false,
		selected_room = "messenger_room_1"
	}

	function sidebar:draw()
		rectfill(self.x, self.y, self.x + self.width, self.y + self.height, 1)

		for button in all(self.buttons) do
			local color = button.room_name == self.selected_room and 13 or (button.hovered and 6 or 5)
			rectfill(button.x, button.y, button.x + button.width, button.y + button.height, color)
			print(button.label, button.x + 3, button.y + 4, 7)
		end
	end

	function sidebar:select_room(room_name)
		self.selected_room = room_name
		on_room_selected(room_name)
	end

	function sidebar:update()
		local mouse_x, mouse_y, mouse_buttons = mouse()
		local left_down = mouse_buttons > 0

		for button in all(self.buttons) do
			button.hovered = mouse_x >= button.x and mouse_x <= button.x + button.width
				and mouse_y >= button.y and mouse_y <= button.y + button.height
			if left_down and not self.mouse_down and button.hovered then
				button.click()
			end
		end

		self.mouse_down = left_down
	end

	function sidebar:resize()
		self.x = 5
		self.y = 5
		self.width = 45
		self.height = scr.h - 10

		for button in all(self.buttons) do
			button:resize()
		end
	end

	function sidebar:add_room_button(label, room_name, row)
		local button = {
			label = label,
			room_name = room_name,
			width = sidebar.width - 6,
			height = 15,
			resize = function(self)
				self.x = sidebar.x + 3
				self.y = sidebar.y + 4 + row * (self.height + 3)
				self.width = sidebar.width - 6
			end,
			click = function()
				sidebar:select_room(room_name)
			end
		}

		button:resize()
		add(sidebar.buttons, button)
	end

	sidebar:add_room_button("Room 1", "messenger_room_1", 0)
	sidebar:add_room_button("Room 2", "messenger_room_2", 1)

	return sidebar
end