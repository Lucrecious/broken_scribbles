extends Reference

class_name Constants

const VALID_DRAW_SECONDS := [15.0, 30.0, 60.0, 90.0]
const DEFAULT_DRAW_SECOND_INDEX := 2
static func get_draw_seconds(index : int) -> float:
	if index < 0 || index >= VALID_DRAW_SECONDS.size(): return VALID_DRAW_SECONDS[DEFAULT_DRAW_SECOND_INDEX]
	return VALID_DRAW_SECONDS[index]

const Category_None = 0

const Words = {
	Angel = true,
	Eyeball = true,
	Pizza = true,
	Angry = true,
	Fireworks = true,
	Pumpkin = true,
	Baby = true,
	Flower = true,
	Rainbow = true,
	Beard = true,
	Flying_Saucer = true,
	Recycle = true,
	Bible = true,
	Giraffe = true,
	Sand_Castle = true,
	Bikini = true,
	Glasses = true,
	Snowflake = true,
	Book = true,
	High_Heel = true,
	Stairs = true,
	Bucket = true,
	Ice_Cream_Cone = true,
	Starfish = true,
	Bumble_Bee = true,
	Igloo = true,
	Strawberry = true,
	Butterfly = true,
	Lady_Bug = true,
	Sun = true,
	Camera = true,
	Lamp = true,
	Tire = true,
	Cat = true,
	Lion = true,
	Toast = true,
	Church = true,
	Mailbox = true,
	Toothbrush = true,
	Crayon = true,
	Night = true,
	Toothpaste = true,
	Dolphin = true,
	Nose = true,
	Truck = true,
	Egg = true,
	Olympics = true,
	Volleyball = true,
	Eiffel_Tower = true,
	Peanut = true,
}
