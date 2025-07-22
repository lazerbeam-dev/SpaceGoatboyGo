extends Resource
class_name Mission

@export var description: String
@export var goals: Array[MissionGoal]
@export var fail_conditions: Array[MissionFailCondition]
@export var bounds: MissionBounds
@export var tolerance_decay_rate: float = 0.05
@export var tolerance_restore_rate: float = 0.01
@export var hard_fail_threshold: float = 0.0
