extends Button

export (int) var bestiary_index: int = - 1
export (Array, Resource) var species: Array = []
export (Color) var unobtained_color: Color = Color.gray

func _ready():
	assert (species.size() == 2)
	if species.size() != 2:
		return

	if bestiary_index < 0:
		bestiary_index = Fusions.fuse_bestiary_index(species[0], species[1])

	if SaveState.species_collection.has_seen_fusion(species[0], species[1]):
		text = Fusions.fuse_names(species[0], species[1])
	else:
		text = "UI_BESTIARY_UNKNOWN_SPECIES"

	if not SaveState.species_collection.has_formed_fusion(species[0], species[1]):
		add_color_override("font_color", unobtained_color)
		add_color_override("font_color_hover", unobtained_color)
		add_color_override("font_color_focus", unobtained_color)
		add_color_override("font_color_pressed", unobtained_color)

	# Accessibility: Connect focus signal
	connect("focus_entered", self, "_on_focus_entered_accessibility")

func _on_focus_entered_accessibility():
	if not Accessibility:
		return

	if species.size() != 2:
		return

	if SaveState.species_collection.has_seen_fusion(species[0], species[1]):
		var fusion_name = Fusions.fuse_names(species[0], species[1])
		var formed = SaveState.species_collection.has_formed_fusion(species[0], species[1])
		var status = "formed" if formed else "seen"
		Accessibility.speak(fusion_name + ", fusion, " + status, true)
	else:
		Accessibility.speak("Unknown fusion", true)

func get_species_data() -> FusionForm:
	return Fusions.fuse_forms(species, 0)
