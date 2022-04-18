extends Node2D

var fromVector = Vector2(0, 0) #start of path
var toVector = Vector2(9, 9) #end of path
var map = null #map that will be used to pathfinding
var mapSize = 10
var aStar = AStar2D.new()

var diagonalEnabled = false 

var drawStart = 50
var drawStartV = Vector2(drawStart, drawStart)
var drawCellSize = 32
var drawCellSizeV = Vector2(drawCellSize, drawCellSize)
var font

var path : PoolVector2Array

func _ready():
	var label = Label.new() #getting font for gui drawing
	font = label.get_font("")
	_start()

func _input(event): #ui controls
	if Input.is_action_just_pressed("ui_diagonals"): #enable/disable diagonals
		_disconnectPoints()
		diagonalEnabled = !diagonalEnabled
		_connectPoints()
		_getPath(fromVector, toVector)
		update()
	elif Input.is_action_just_pressed("ui_reset"): #reset map
		_restart()
		update()
	else:
		var gridPos = (get_local_mouse_position() - drawStartV)/drawCellSizeV #calculating mouse position on grid
		gridPos = Vector2(floor(gridPos.x),floor(gridPos.y))
		if gridPos != fromVector:
			if gridPos.x >= 0 && gridPos.y >= 0:
					if gridPos.x < mapSize && gridPos.y < mapSize:
						if Input.is_action_just_pressed("ui_mouse_right"): #set new start point
							fromVector = gridPos
						elif Input.is_action_just_pressed("ui_mouse_middle"): #set new end point
							toVector = gridPos
						elif Input.is_action_just_pressed("ui_mouse_left"): #enable/disable obstacle
							map[gridPos.x][gridPos.y] *= -1
							#obstacle is created by disabling point by code belowe
							aStar.set_point_disabled(_generateID(gridPos), map[gridPos.x][gridPos.y] == 1)
						#whichever action we choose, we always get new path and update view
						_getPath(fromVector, toVector)
						update()
	
func _draw():
	#draw map description
	draw_string(font, Vector2(drawStart, 25), "Map size: " + str(mapSize) + "x" + str(mapSize))
	draw_string(font, Vector2(drawStart + 190, 25), "Diagonals: " + ("enabled" if diagonalEnabled else "disabled"))
	
	#draw app description
	var descriptionPos = Vector2(drawStart*2 + drawCellSize*mapSize, 75)
	draw_string(font, descriptionPos, "Hello, this is simple example of Godot AStar2D usage.")
	descriptionPos += Vector2(0, drawCellSize)
	descriptionPos += Vector2(0, drawCellSize)
	draw_string(font, descriptionPos, "Press LEFT mouse button to enable/disable OBSTACLE.")
	descriptionPos += Vector2(0, drawCellSize)
	draw_string(font, descriptionPos, "Press RIGHT mouse button to set new STARTING position on map.")
	descriptionPos += Vector2(0, drawCellSize)
	draw_string(font, descriptionPos, "Press MIDDLE mouse button to set new TARGET position on map.")
	descriptionPos += Vector2(0, drawCellSize)
	descriptionPos += Vector2(0, drawCellSize)
	draw_string(font, descriptionPos, "Press V key to enable/disable DIAGONAL movement.")
	descriptionPos += Vector2(0, drawCellSize)
	draw_string(font, descriptionPos, "Press R key to RESET map.")
	
	#draw grid
	for i in range(map.size()+1):
		draw_line(Vector2(drawStart, drawStart+i*drawCellSize), Vector2(drawStart+drawCellSize*mapSize, drawStart+i*drawCellSize), Color.bisque, 1.0, true)
		for j in range(map.size()+1):
			draw_line(Vector2(drawStart+j*drawCellSize, drawStart), Vector2(drawStart+j*drawCellSize, drawStart+drawCellSize*mapSize), Color.bisque, 1.0, true)

	#draw start and end of path
	var rectDrawOffset = drawStartV+Vector2(0, 1)
	draw_rect( Rect2(fromVector*drawCellSize+rectDrawOffset, drawCellSizeV-Vector2(1,1)), Color.blue)
	draw_rect( Rect2(toVector*drawCellSize+rectDrawOffset, drawCellSizeV-Vector2(1,1)), Color.red)
	
	#draw obstacles
	for i in range(mapSize):
		for j in range(mapSize):
			if map[i][j] == 1:
				draw_rect( Rect2( Vector2(i, j) * drawCellSize + rectDrawOffset, drawCellSizeV-Vector2.ONE ), Color.black )
	
	#draw path
	if path != null:
		for i in range(path.size()-1):
			var perc = float(i)/path.size()
			draw_rect( Rect2(path[i] * drawCellSize + rectDrawOffset, drawCellSizeV-Vector2.ONE), Color(perc, 1, 1-perc))

func _start(): #prepares all needed things
	_generateMap()
	_addPoints()
	_connectPoints()
	_getPath(fromVector, toVector)

func _restart(): #resets all settings
	_generateMap()
	_disconnectPoints()
	diagonalEnabled = false
	fromVector = Vector2(0, 0)
	toVector = Vector2(9, 9)
	_connectPoints()
	_enableAllPoints()
	_getPath(fromVector, toVector)

func _generateMap(): #generates basic 10x10 array, with all cells set as -1
	map = []
	map.resize(mapSize)
	for i in range(mapSize):
		map[i] = []
		map[i].resize(mapSize)
		for j in range(mapSize):
			map[i][j] = -1

func _addPoints(): #reads map and creates a* point on each cell
	for i in range(mapSize):
		for j in range(mapSize):
			var pos = Vector2(i, j)
			aStar.add_point(_generateID(pos), pos)
				
func _connectPoints(): #connects each cell with corresponding top, bottom, left and right cell
						#or with every neighbouring cell, if "diagonalEnabled" is true
	var neighbours = [Vector2(1, 0), Vector2(-1, 0), Vector2(0,1), Vector2(0,-1)]
	if diagonalEnabled:
		neighbours.append_array([Vector2(1, 1), Vector2(-1, -1), Vector2(-1,1), Vector2(1,-1)])
	for i in range(mapSize):
		for j in range(mapSize):
			var pos = Vector2(i, j)
			for n in neighbours:
				var nextPos = pos + n
				if nextPos.x >= 0 && nextPos.x < mapSize:
					if nextPos.y >= 0 && nextPos.y < mapSize:
						aStar.connect_points(_generateID(pos), _generateID(nextPos), false)

func _disconnectPoints(): #disconnects points - needed when swapping diagonals on/off
	var neighbours = [Vector2(1, 0), Vector2(-1, 0), Vector2(0,1), Vector2(0,-1)]
	if diagonalEnabled:
		neighbours.append_array([Vector2(1, 1), Vector2(-1, -1), Vector2(-1,1), Vector2(1,-1)])
	for i in range(mapSize):
		for j in range(mapSize):
			var pos = Vector2(i, j)
			for n in neighbours:
				var nextPos = pos + n
				if nextPos.x >= 0 && nextPos.x < mapSize:
					if nextPos.y >= 0 && nextPos.y < mapSize:
						aStar.disconnect_points(_generateID(pos), _generateID(nextPos))

func _getPath(from, to): #Godot's built-in aStar script to find path
	path = aStar.get_point_path(_generateID(from), _generateID(to))
	path.remove(0) #we remove first step of path, since it's our starting point

func _generateID(pos): #generates unique id for each position - just trust the math
	var x = pos.x
	var y = pos.y
	return (x + y) * (x + y + 1) / 2 + y

func _enableAllPoints(): #needed when resetting map - enables all points again
	for i in range(mapSize):
		for j in range(mapSize):
			var pos = Vector2(i, j)
			aStar.set_point_disabled(_generateID(pos), false)
