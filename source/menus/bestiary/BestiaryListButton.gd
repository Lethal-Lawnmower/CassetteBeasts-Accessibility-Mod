extends Button

export (Resource) var species: Resource
export (Color) var unobtained_color: Color = Color.gray

onready var number_label = $NumberLabel

func _ready():
	var species: MonsterForm = self.species as MonsterForm

	number_label.text = MonsterForms.get_bestiary_code(species)

	if species and SaveState.species_collection.has_seen_species(species):
		text = species.name
	else:
		text = "UI_BESTIARY_UNKNOWN_SPECIES"

	if not species or not SaveState.species_collection.has_bestiary_data_requirement(species, 0):
		add_color_override("font_color", unobtained_color)
		add_color_override("font_color_hover", unobtained_color)
		add_color_override("font_color_focus", unobtained_color)
		add_color_override("font_color_pressed", unobtained_color)
		number_label.add_color_override("font_color", unobtained_color)

	# Accessibility: Connect focus signal
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	var species_form: MonsterForm = self.species as MonsterForm
	var code = MonsterForms.get_bestiary_code(species_form) if species_form else ""

	if species_form and SaveState.species_collection.has_seen_species(species_form):
		var species_name = Loc.tr(species_form.name)
		var obtained = SaveState.species_collection.has_obtained_species(species_form)
		var status = "recorded" if obtained else "seen"
		Accessibility.speak(code + ", " + species_name + ", " + status, true)
	else:
		Accessibility.speak(code + ", unknown", true)

func get_species_data() -> MonsterForm:
	assert (species is MonsterForm or species == null)
	return species as MonsterForm
