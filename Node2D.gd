extends Node2D

var fromVector = Vector2(0, 0)
var toVector = Vector2(9, 9)
var map = null
var mapSize = 10
var mapSizeV = Vector2(mapSize, mapSize)
onready var aStar = AStar2D.new()

var drawStart = 50
var drawStartV = Vector2(drawStart, drawStart)
var drawCellSize = 32
var drawCellSizeV = Vector2(drawCellSize, drawCellSize)
var font

var path : PoolVector2Array

func _ready():
	var label = Label.new()
	font = label.get_font("")
	_start()
	
func _process(delta):
	if Input.is_action_just_pressed("ui_mouse_left") || Input.is_action_just_pressed("ui_mouse_right"):
		var gridPos = (get_local_mouse_position() - drawStartV)/drawCellSizeV
		gridPos = Vector2(floor(gridPos.x),floor(gridPos.y))
		if gridPos != fromVector:
			if gridPos.x >= 0 && gridPos.y >= 0:
					if gridPos.x < mapSize && gridPos.y < mapSize:
						if Input.is_action_just_pressed("ui_mouse_left"):
							fromVector = gridPos
						else:
							toVector = gridPos
						_start()
						update()
	
func _draw():
	if map != null:
		draw_string(font, Vector2(drawStart, 25), "Map size: " + str(mapSize) + "x" + str(mapSize))
		var descriptionPos = Vector2(drawStart*2 + drawCellSize*mapSize, 25)
		draw_string(font, descriptionPos, "Hello, this is simple example of Godot AStar2D usage.")
		descriptionPos += Vector2(0, drawCellSize)
		descriptionPos += Vector2(0, drawCellSize)
		descriptionPos += Vector2(0, drawCellSize)
		draw_string(font, descriptionPos, "Press left mouse button to set new starting position on map.")
		descriptionPos += Vector2(0, drawCellSize)
		draw_string(font, descriptionPos, "Press right mouse button to set new target position on map.")
		
		for i in range(map.size()+1):
			draw_line(Vector2(drawStart, drawStart+i*drawCellSize), Vector2(drawStart+drawCellSize*mapSize, drawStart+i*drawCellSize), Color.bisque, 1.0, true)
			for j in range(map.size()+1):
				draw_line(Vector2(drawStart+j*drawCellSize, drawStart), Vector2(drawStart+j*drawCellSize, drawStart+drawCellSize*mapSize), Color.bisque, 1.0, true)

		var rectDrawOffset = drawStartV+Vector2(0, 1)
		draw_rect( Rect2(fromVector*drawCellSize+rectDrawOffset, drawCellSizeV-Vector2(1,1)), Color.blue)
		draw_rect( Rect2(toVector*drawCellSize+rectDrawOffset, drawCellSizeV-Vector2(1,1)), Color.red)
		
		var alp = 1
		if path != null:
			for i in range(path.size()):
				var perc = float(i)/path.size()
				if i != path.size()-1:
					draw_rect( Rect2(path[i] * drawCellSize + rectDrawOffset, drawCellSizeV-Vector2.ONE), Color(perc, 1, 1-perc, alp))

func _start():
	_generateMap()
	_addPoints()
	_connectPoints()
	_getPath(fromVector, toVector)

func _generateMap():
	map = []
	map.resize(mapSize)
	for i in range(mapSize):
		map[i] = []
		map[i].resize(mapSize)
	
	map[toVector.x][toVector.y] = "T"
	map[fromVector.x][fromVector.y] = "F"

func _addPoints():
	for i in range(mapSize):
		for j in range(mapSize):
			var pos = Vector2(i, j)
			aStar.add_point(_generateID(pos), pos)
				
func _connectPoints():
	for i in range(mapSize):
		for j in range(mapSize):
			var neighbours = [Vector2(1, 0), Vector2(-1, 0), Vector2(0,1), Vector2(0,-1)]
			var pos = Vector2(i, j)
			for n in neighbours:
				var nextPos = pos + n
				if nextPos.x >= 0 && nextPos.x < mapSize:
					if nextPos.y >= 0 && nextPos.y < mapSize:
						aStar.connect_points(_generateID(pos), _generateID(nextPos), false)	
	
func _getPath(from, to):
	path = aStar.get_point_path(_generateID(from), _generateID(to))
	path.remove(0)

func _generateID(pos):
	var x = pos.x
	var y = pos.y
	return (x + y) * (x + y + 1) / 2 + y
