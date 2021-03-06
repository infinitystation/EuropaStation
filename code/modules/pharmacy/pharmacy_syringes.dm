////////////////////////////////////////////////////////////////////////////////
/// Syringes.
////////////////////////////////////////////////////////////////////////////////
#define SYRINGE_DRAW 0
#define SYRINGE_INJECT 1
#define SYRINGE_BROKEN 2

/obj/item/reagent_containers/syringe
	name = "syringe"
	desc = "A syringe."
	icon = 'icons/obj/syringe.dmi'
	item_state = "syringe_0"
	icon_state = "0"
	matter = list("glass" = 150)
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = null
	volume = 15
	w_class = 1
	slot_flags = SLOT_EARS
	sharp = 1
	unacidable = 1 //glass
	auto_init = TRUE
	var/image/filling // Reference to overlay, used by syringe gun canisters.
	var/actual_reagent_name
	var/obfuscate_contents = TRUE
	var/mode = SYRINGE_DRAW
	var/visible_name = "a syringe"
	var/time = 30

/obj/item/reagent_containers/syringe/initialize()
	. = ..()
	if(reagents && reagents.total_volume)
		mode = SYRINGE_INJECT
		if(obfuscate_contents)
			var/reagent_id = reagents.get_master_reagent_id()
			if(reagent_id)
				actual_reagent_name = reagents.get_master_reagent_name()
				var/medication_name = get_random_medication_name_for_reagent(reagent_id)
				desc = "A syringe labelled with \'[medication_name]\'."
		if(actual_reagent_name && istype(loc, /obj/item/storage/firstaid))
			name = "syringe ([actual_reagent_name])"
	update_icon()

/obj/item/reagent_containers/syringe/get_default_codex_value(var/mob/user)
	return (HAS_ASPECT(user, ASPECT_PHARMACIST) && !isnull(actual_reagent_name)) ? "[actual_reagent_name] (chemical)" : ..()

/obj/item/reagent_containers/syringe/examine(var/mob/user)
	. = ..(user, 1)
	if(!isnull(actual_reagent_name) && HAS_ASPECT(user, ASPECT_PHARMACIST))
		to_chat(user, "<span class='notice'>As far as you know, the active ingredient is <b>[actual_reagent_name]</b>.</span>")

/obj/item/reagent_containers/syringe/on_reagent_change()
	. = ..()
	update_icon()

/obj/item/reagent_containers/syringe/attack_self(var/mob/user)
	switch(mode)
		if(SYRINGE_DRAW)
			mode = SYRINGE_INJECT
		if(SYRINGE_INJECT)
			mode = SYRINGE_DRAW
		if(SYRINGE_BROKEN)
			return
	update_icon()

/obj/item/reagent_containers/syringe/attack_hand()
	..()
	update_icon()

/obj/item/reagent_containers/syringe/attackby(var/obj/item/I, var/mob/user)
	return

/obj/item/reagent_containers/syringe/do_surgery(mob/living/carbon/M, mob/living/user)
	if(user.a_intent == I_HURT)
		return 0
	if(user.a_intent != I_HELP) //in case it is ever used as a surgery tool
		return ..()
	afterattack(M, user, 1)
	return 1

/obj/item/reagent_containers/syringe/afterattack(var/obj/target, var/mob/user, var/proximity)
	if(!proximity || !target.reagents)
		return

	if(mode == SYRINGE_BROKEN)
		to_chat(user, "<span class='warning'>This syringe is broken!</span>")
		return

	if(user.a_intent == I_HURT && ismob(target))
		if(HAS_ASPECT(user, ASPECT_CLUMSY) && prob(50))
			target = user
		syringestab(target, user)
		return

	var/target_zone = check_zone(user.zone_sel.selecting)

	switch(mode)
		if(SYRINGE_DRAW)

			if(!reagents.get_free_space())
				to_chat(user, "<span class='warning'>The syringe is full.</span>")
				mode = SYRINGE_INJECT
				return

			if(ismob(target))//Blood!
				if(reagents.has_reagent("blood"))
					to_chat(user, "<span class='notice'>There is already a blood sample in this syringe.</span>")
					return
				if(istype(target, /mob/living/carbon))
					if(istype(target, /mob/living/carbon/slime))
						to_chat(user, "<span class='warning'>You are unable to locate any blood.</span>")
						return
					var/amount = reagents.get_free_space()
					var/mob/living/carbon/T = target
					var/injtime = time //Taking a blood sample through a hardsuit takes longer due to needing to find a port.
					var/allow = T.can_inject(user, target_zone)
					if(!allow)
						return
					if(allow == INJECTION_PORT)
						injtime *= 2
						user.visible_message("<span class='warning'>\The [user] begins hunting for an injection port on [target]'s suit!</span>")
					else
						user.visible_message("<span class='warning'>\The [user] is trying to take a blood sample from [target].</span>")

					user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
					user.do_attack_animation(target)

					if(!do_mob(user, target, injtime))
						return

					if(take_blood_sample(T, amount))
						user.visible_message("<span class='notice'>\The [user] takes a blood sample from \the [target].</span>")
					else
						to_chat(user, "<span class='warning'>You cannot find any blood.</span>")
						user.visible_message("<span class='notice'>\The [user] withdraws the empty syringe.</span>")

			else //if not mob
				if(!target.reagents.total_volume)
					to_chat(user, "<span class='notice'>[target] is empty.</span>")
					return

				if(!target.is_open_container() && !istype(target, /obj/structure/reagent_dispensers) && !istype(target, /obj/item/slime_extract))
					to_chat(user, "<span class='notice'>You cannot directly remove reagents from this object.</span>")
					return

				var/trans = target.reagents.trans_to_obj(src, amount_per_transfer_from_this)
				to_chat(user, "<span class='notice'>You fill the syringe with [trans] units of the solution.</span>")
				update_icon()

			if(!reagents.get_free_space())
				mode = SYRINGE_INJECT
				update_icon()

		if(SYRINGE_INJECT)
			if(!reagents.total_volume)
				to_chat(user, "<span class='notice'>The syringe is empty.</span>")
				mode = SYRINGE_DRAW
				return
			if(istype(target, /obj/item/implantcase/chem))
				return

			if(!target.is_open_container() && !ismob(target) && !istype(target, /obj/item/reagent_containers/food) && !istype(target, /obj/item/slime_extract) && !istype(target, /obj/item/clothing/mask/smokable/cigarette) && !istype(target, /obj/item/storage/fancy/cigarettes))
				to_chat(user, "<span class='notice'>You cannot directly fill this object.</span>")
				return
			if(!target.reagents.get_free_space())
				to_chat(user, "<span class='notice'>[target] is full.</span>")
				return

			if(isliving(target) && target != user)
				var/mob/living/L = target
				var/injtime = time //Injecting through a hardsuit takes longer due to needing to find a port.
				var/allow = L.can_inject(user, target_zone)
				if(!allow)
					return
				if(allow == INJECTION_PORT)
					injtime *= 2
					user.visible_message("<span class='warning'>\The [user] begins hunting for an injection port on [target]'s suit!</span>")
				else
					user.visible_message("<span class='warning'>\The [user] is trying to inject [target] with [visible_name]!</span>")

				user.setClickCooldown(DEFAULT_QUICK_COOLDOWN)
				user.do_attack_animation(target)

				if(!do_mob(user, target, injtime))
					return

				user.visible_message("<span class='warning'>[user] injects [target] with the syringe!</span>")

			var/trans
			if(ismob(target))
				var/contained = reagentlist()
				trans = reagents.trans_to_mob(target, amount_per_transfer_from_this, CHEM_BLOOD)
				admin_inject_log(user, target, src, contained, trans)
			else
				trans = reagents.trans_to(target, amount_per_transfer_from_this)
			to_chat(user, "<span class='notice'>You inject [trans] units of the solution. The syringe now contains [src.reagents.total_volume] units.</span>")
			if (reagents.total_volume <= 0 && mode == SYRINGE_INJECT)
				mode = SYRINGE_DRAW
				update_icon()

/obj/item/reagent_containers/syringe/dropped()
	. = ..()
	update_icon()

/obj/item/reagent_containers/syringe/pickup()
	. = ..()
	update_icon()

/obj/item/reagent_containers/syringe/update_icon()
	cut_overlays()
	if(mode == SYRINGE_BROKEN)
		icon_state = "broken"
		return

	var/rounded_vol = round(reagents.total_volume, round(reagents.maximum_volume / 3))
	if(ismob(loc))
		switch(mode)
			if (SYRINGE_DRAW)
				add_overlay("draw")
			if (SYRINGE_INJECT)
				add_overlay("inject")
	icon_state = "[rounded_vol]"
	item_state = "syringe_[rounded_vol]"

	if(reagents.total_volume)
		var/fill_icon = "syringe[rounded_vol]"
		var/fill_colour = reagents.get_color()
		var/cache_key = "[fill_icon]-[fill_colour]"
		var/last_filling = filling
		if(isnull(reagent_syringe_overlays[cache_key]))
			filling = image('icons/obj/reagentfillings.dmi', src, fill_icon)
			filling.color = fill_colour
			reagent_syringe_overlays[cache_key] = filling
		filling = reagent_syringe_overlays[cache_key]
		add_overlay(filling)
		if(filling != last_filling && istype(loc, /obj/item/syringe_cartridge))
			var/obj/item/syringe_cartridge/cart = loc
			cart.update_icon()

/obj/item/reagent_containers/syringe/proc/syringestab(var/mob/living/carbon/target, var/mob/living/carbon/user)

	if(istype(target, /mob/living/carbon/human))

		var/mob/living/carbon/human/H = target
		var/target_zone = ran_zone(check_zone(user.zone_sel.selecting, target))
		var/obj/item/organ/external/affecting = H.get_organ(target_zone)

		if (!affecting || affecting.is_stump())
			to_chat(user, "<span class='danger'>They are missing that limb!</span>")
			return

		var/hit_area = affecting.name

		if((user != target) && H.check_shields(7, src, user, "\the [src]"))
			return

		if (target != user && H.getarmor(target_zone, "melee") > 5 && prob(50))
			user.visible_message("<span class='danger'>\The [user] tries to stab \the [target] in \the [hit_area] with \the [src], but the attack is deflected by armor!</span>")
			user.drop_from_inventory(src)
			qdel(src)

			admin_attack_log(user, target, \
			 "Attacked [target.name] ([target.ckey]) with \the [src] (INTENT: HARM).", \
			 "Attacked by [user.name] ([user.ckey]) with [src.name] (INTENT: HARM).", \
			 "[key_name_admin(user)] attacked [key_name_admin(target)] with [src.name] (INTENT: HARM) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)" \
			 )

			return

		user.visible_message("<span class='danger'>[user] stabs [target] in \the [hit_area] with [src.name]!</span>")
		if(affecting.take_damage(3))
			H.UpdateDamageIcon()

	else
		user.visible_message("<span class='danger'>[user] stabs [target] with [src.name]!</span>")
		target.take_organ_damage(3)// 7 is the same as crowbar punch

	var/syringestab_amount_transferred = rand(0, (reagents.total_volume - 5)) //nerfed by popular demand
	var/contained_reagents = reagents.get_reagents()
	var/trans = reagents.trans_to_mob(target, syringestab_amount_transferred, CHEM_BLOOD)
	if(isnull(trans)) trans = 0
	admin_inject_log(user, target, src, contained_reagents, trans, violent=1)

	break_syringe(target, user)

/obj/item/reagent_containers/syringe/proc/break_syringe(mob/living/carbon/target, mob/living/carbon/user)
	desc += " It is broken."
	mode = SYRINGE_BROKEN
	if(target)
		add_blood(target)
	if(user)
		add_fingerprint(user)
	update_icon()

/obj/item/reagent_containers/syringe/proc/take_blood_sample(var/mob/living/carbon/T, var/amount)
	var/datum/reagent/B
	if(istype(T, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = T
		if(!H.should_have_organ(BP_HEART))
			H.reagents.trans_to_obj(src, amount)
		else
			B = T.take_blood(src, amount)
	else
		B = T.take_blood(src,amount)

	if (B)
		reagents.reagent_list += B
		reagents.update_total()
		on_reagent_change()
		reagents.handle_reactions()
	return B
