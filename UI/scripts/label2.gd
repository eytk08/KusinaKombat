extends Label

var full_text = "Apo, anong putahe ang nais mong lutuin? 
Ilista mo nang mabili sa palengke
Aba ay tara na't pumunta, baka tayo ay maubusan!
"  
var typing_speed = 0.05  # How fast letters appear 

func _ready():
	text = ""  # empty text
	start_typing()

func start_typing():
	for letter in full_text.length():  # Loop 
		text += full_text[letter]  # one letter at a time
		await get_tree().create_timer(typing_speed).timeout  
