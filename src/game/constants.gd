extends Reference

class_name Constants

const VALID_DRAW_SECONDS := [15.0, 30.0, 60.0, 90.0]
const DEFAULT_DRAW_SECOND_INDEX := 1
static func get_draw_seconds(index : int) -> float:
	if index < 0 || index >= VALID_DRAW_SECONDS.size(): return VALID_DRAW_SECONDS[DEFAULT_DRAW_SECOND_INDEX]
	return VALID_DRAW_SECONDS[index]

const Category_None = 0

const FeelingAdjectives := {
	great = true,
	playful = true,
	calm = true,
	confident = true,
	courageous = true,
	peaceful = true,
	reliable = true,
	joyous = true,
	energetic = true,
	at_ease = true,
	easy = true,
	lucky = true,
	liberated = true,
	comfortable = true,
	amazed = true,
	fortunate = true,
	optimistic = true,
	pleased = true,
	free = true,
	delighted = true,
	provocative = true,
	encouraged = true,
	sympathetic = true,
	overjoyed = true,
	impulsive = true,
	clever = true,
	interested = true,
	Gleeful = true,
	Free = true,
	surprised = true,
	satisfied = true,
	thankful = true,
	frisky = true,
	content = true,
	receptive = true,
	important = true,
	animated = true,
	quiet = true,
	accepting = true,
	festive = true,
	spirited = true,
	certain = true,
	kind = true,
	ecstatic = true,
	thrilled = true,
	relaxed = true,
	wonderful = true,
	serene = true,
	glad = true,
	cheerful = true,
	bright = true,
	sunny = true,
	blessed = true,
	merry = true,
	reassured = true,
	elated = true,
	jubilant = true,
}


const Animals := {
	Alligator = true,
	Anteater = true,
	Armadillo = true,
	Auroch = true,
	Axolotl = true,
	Badger = true,
	Bat = true,
	Bear = true,
	Beaver = true,
	Buffalo = true,
	Camel = true,
	Capybara = true,
	Chameleon = true,
	Cheetah = true,
	Chinchilla = true,
	Chipmunk = true,
	Chupacabra = true,
	Cormorant = true,
	Coyote = true,
	Crow = true,
	Dingo = true,
	Dinosaur = true,
	Dog = true,
	Dolphin = true,
	Duck = true,
	Elephant = true,
	Ferret = true,
	Fox = true,
	Frog = true,
	Giraffe = true,
	Gopher = true,
	Grizzly = true,
	Hedgehog = true,
	Hippo = true,
	Hyena = true,
	Ibex = true,
	Ifrit = true,
	Iguana = true,
	Jackal = true,
	Kangaroo = true,
	Koala = true,
	Kraken = true,
	Lemur = true,
	Leopard = true,
	Liger = true,
	Lion = true,
	Llama = true,
	Loris = true,
	Manatee = true,
	Mink = true,
	Monkey = true,
	Moose = true,
	Narwhal = true,
	Nyan_Cat = true,
	Orangutan = true,
	Otter = true,
	Panda = true,
	Penguin = true,
	Platypus = true,
	Pumpkin = true,
	Python = true,
	Quagga = true,
	Rabbit = true,
	Raccoon = true,
	Rhino = true,
	Sheep = true,
	Shrew = true,
	Skunk = true,
	Squirrel = true,
	Tiger = true,
	Turtle = true,
	Walrus = true,
	Wolf = true,
	Wolverine = true,
	Wombat = true,
}

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
