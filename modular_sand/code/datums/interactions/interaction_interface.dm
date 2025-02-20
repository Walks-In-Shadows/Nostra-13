/// Attempts to open the tgui menu
/mob/living/verb/interact_with()
	set name = "Interact With"
	set desc = "Perform an interaction with someone."
	set category = "IC"
	set src in view()

	if(!usr.mind) //Mindless boys, honestly just don't, it's better this way
		return
	if(!usr.mind.interaction_holder)
		usr.mind.interaction_holder = new(usr.mind)
	usr.mind.interaction_holder.target = src
	usr.mind.interaction_holder.ui_interact(usr)

/// Allows "cyborg" players to change gender at will
/mob/living/silicon/robot/verb/toggle_gender()
	set category = "IC"
	set name = "Set Gender"
	set desc = "Allows you to set your gender."

	if(stat != CONSCIOUS)
		to_chat(usr, "<span class='warning'>You cannot toggle your gender while unconcious!</span>")
		return

	var/choice = alert(usr, "Select Gender.", "Gender", "Both", "Male", "Female")
	switch(choice)
		if("Both")
			has_penis = TRUE
			has_vagina = TRUE
		if("Male")
			has_penis = TRUE
			has_vagina = FALSE
		if("Female")
			has_penis = FALSE
			has_vagina = TRUE

#define INTERACTION_NORMAL 0
#define INTERACTION_LEWD 1
#define INTERACTION_EXTREME 2

/datum/mind
	var/datum/interaction_menu/interaction_holder

/datum/mind/New(key)
	. = ..()
	interaction_holder = new(src)

/// The menu itself, only var is target which is the mob you are interacting with
/datum/interaction_menu
	var/mob/living/target

/datum/interaction_menu/ui_state(mob/user)
	return GLOB.conscious_state

/datum/interaction_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MobInteraction", "Interactions")
		ui.open()

/datum/interaction_menu/ui_data(mob/user)
	var/mob/living/self = user
	var/list/data = list()
	data["isTargetSelf"] = target == self
	data["interactingWith"] = target != self ? "Interacting with \the [target]..." : "Interacting with yourself..."
	data["selfAttributes"] = self.list_interaction_attributes(self)
	if(target != self)
		data["theirAttributes"] = target.list_interaction_attributes(self)

	make_interactions()
	var/list/sent_interactions = list()
	for(var/interaction_key in GLOB.interactions)
		var/datum/interaction/I = GLOB.interactions[interaction_key]
		if(I.evaluate_user(self, action_check = FALSE) && I.evaluate_target(self, target))
			if(I.user_is_target == TRUE && target != self)
				continue
			var/list/interaction = list()
			interaction["key"] = I.command
			interaction["desc"] = I.description
			if(istype(I, /datum/interaction/lewd))
				var/datum/interaction/lewd/O = I
				if(O.extreme)
					interaction["type"] = INTERACTION_EXTREME
				else
					interaction["type"] = INTERACTION_LEWD
			else
				interaction["type"] = INTERACTION_NORMAL
			sent_interactions += list(interaction)
	data["interactions"] = sent_interactions

	return data

/datum/interaction_menu/ui_act(action, params)
	if(..())
		return
	switch(action)
		if("interact")
			var/datum/interaction/o = GLOB.interactions[params["interaction"]]
			if(o)
				o.do_action(usr, target)
				return TRUE
			return FALSE

#undef INTERACTION_NORMAL
#undef INTERACTION_LEWD
#undef INTERACTION_EXTREME
