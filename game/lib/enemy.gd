class_name Enemy extends CharacterBody3D

@onready var anim:AnimationPlayer = $AnimationPlayer

const ANIM_IDLE = "goblin/looking_around_2"
const ANIM_ATTACK = "goblin/bash"
const ANIM_HIT = "goblin/reaction"
const ANIM_WALK = "goblin/walking"
const ANIM_DIE = "goblin/react_deatch_backward"

func _ready():
	anim.play(ANIM_IDLE)
