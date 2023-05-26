extends Node

@onready var CHUNKS := $/root/world/chunks
@onready var BLKS := $/root/world/chunks/GridMap
@onready var KIRA := $/root/world/kira/Kira
const dimension := Vector3i(32, 64, 16)
