require("luciole")

load_texture("pieces", "./pieces.png")

create_subtexture("q", "pieces", 0, 0, 16, 16)
create_subtexture("k", "pieces", 16, 0, 16, 16)
create_subtexture("b", "pieces", 32, 0, 16, 16)
create_subtexture("n", "pieces", 48, 0, 16, 16)
create_subtexture("r", "pieces", 64, 0, 16, 16)
create_subtexture("p", "pieces", 80, 0, 16, 16)
create_subtexture("Q", "pieces", 0, 16, 16, 16)
create_subtexture("K", "pieces", 16, 16, 16, 16)
create_subtexture("B", "pieces", 32, 16, 16, 16)
create_subtexture("N", "pieces", 48, 16, 16, 16)
create_subtexture("R", "pieces", 64, 16, 16, 16)
create_subtexture("P", "pieces", 80, 16, 16, 16)

load_font("ui_font", "monogram.ttf", 32)

board_files = {"a", "b", "c", "d", "e", "f", "g", "h"}

set_screen_dimensions(608,608)
screen_width, screen_height = get_screen_dimensions()

game_board = {}

for y=1,8 do
	game_board[y] = {}
	for x=1,8 do
		game_board[x] = {}
	end
end

OnNewGame()

last_tick = 0
local player_turn = false
local cpu_vs_cpu = false

local selected_square = ""
local target_square = ""
function x_y_to_board(board_x, board_y, x, y)
	x = x - board_x
	y = y - board_y
	
	x = math.floor(x/64)+1
	y = math.floor(y/64)+1
	return board_files[x]..tostring(y)
end

function x_y_to_index(board_x, board_y, x, y)
	x = x - board_x
	y = y - board_y
	
	x = math.floor(x/64)+1
	y = math.floor(y/64)+1
	return {x,(y)}
end

function update()
	local current_tick = get_ticks()
	screen_width, screen_height = get_screen_dimensions()
	if screen_width ~= 608 or screen_height ~=  608 then
		set_screen_dimensions(608,608)
	end
	if get_key_pressed("f1") then
		cpu_vs_cpu = not cpu_vs_cpu
	end
			
	if not cpu_vs_cpu and player_turn then
		if get_mouse_pressed("left") then
			local x, y = get_mouse_position()
			if selected_square == "" then
				selected_square = x_y_to_board(48, 48, x, y)
				selected_index = x_y_to_index(48, 48, x, y)
			else
				selected_square = selected_square..x_y_to_board(48, 48, x, y)
				
				-- use the players input
				OnMove(selected_square)
				
				selected_square = ""
				selected_index = nil
				player_turn = false
			end
		elseif get_key_pressed("m") then
			local move = OnGo()
			if (move ~= nil) then
				OnMove(move)
				player_turn = false
			else
				OnNewGame()
				player_turn = false
			end
		end
	else
		local move = OnGo()
		if (move ~= nil) then
			OnMove(move)
			if not cpu_vs_cpu then
				player_turn = true
			end
		else
			OnNewGame()
		end
	end
	
	last_tick = current_tick
end

function draw_chess_board(x_draw, y_draw, size)
	local x_init = x_draw
	local y_init = y_draw
	for x=1,8 do
		for y=1,8 do
			if board_files[x]..tostring(y) == selected_square then
				render_rectangle(x_draw, y_draw, size, size, 100, 200, 100, 255, false)
				render_border(x_draw, y_draw, size, size, 0, 0, 0, 255, false)
			elseif y % 2 == 0 then
				if x % 2 == 0 then
					render_rectangle(x_draw, y_draw, size, size, 200, 200, 200, 255, false)
				else
					render_rectangle(x_draw, y_draw, size, size, 127, 127, 127, 255, false)
				end
				render_border(x_draw, y_draw, size, size, 0, 0, 0, 255, false)
			else
				if x % 2 == 0 then
					render_rectangle(x_draw, y_draw, size, size, 127, 127, 127, 255, false)
				else
					render_rectangle(x_draw, y_draw, size, size, 200, 200, 200, 255, false)
				end
				render_border(x_draw, y_draw, size, size, 64, 64, 64, 255, false)
			end
			if LPos.piecePlacement[x][y] ~= nil then
				
				render_subtexture(LPos.piecePlacement[x][y], x_draw + 32, y_draw + 32, 48, 48, true, 0)
				
				--render_text("ui_font", tostring(LPos.piecePlacement[x][y]), x_draw+36, y_draw+36, 0,0,0,true)
			end
			y_draw = y_draw + size
		end
		y_draw = y_init
		x_draw = x_draw + size
	end
end

function render()
	render_border(0, 0, screen_width-1, screen_height-1, 0, 255, 0, 255, false)
	
	draw_chess_board(48,48,64)
end
