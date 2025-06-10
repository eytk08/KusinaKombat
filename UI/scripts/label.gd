extends Label

var full_text = "Apo, nandiyan ka na pala! \nHalika na sa loob at tulungan mo ako maghanda ng makakain \n Nais kong subukan ang iyong kakayahan sa pagluluto. "  #  text to type
var typing_speed = 0.05  # How fast letters appear 

func _ready():
	text = ""  # empty text
	start_typing()

func start_typing():
	for letter in full_text.length():  # Loop 
		text += full_text[letter]  # one letter at a time
		await get_tree().create_timer(typing_speed).timeout  
