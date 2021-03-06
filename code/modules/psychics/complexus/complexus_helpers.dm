/datum/psi_complexus/proc/cancel()
	owner << 'sound/effects/psi/power_fail.ogg'
	if(LAZYLEN(manifested_items))
		for(var/thing in manifested_items)
			owner.drop_from_inventory(thing)
			qdel(thing)
		manifested_items = null

/datum/psi_complexus/proc/stunned(var/amount)
	var/old_stun = stun
	stun = max(stun, amount)
	if(amount && !old_stun)
		to_chat(owner, "<span class='danger'>Your concentration has been shattered! You cannot focus your psi power!</span>")
		ui.update_icon()
	cancel()

/datum/psi_complexus/proc/get_rank(var/faculty)
	return (LAZYLEN(ranks) && ranks[faculty] ? ranks[faculty] : 0)

/datum/psi_complexus/proc/set_rank(var/faculty, var/rank, var/defer_update, var/temporary)
	if(get_rank(faculty) != rank)
		if(!ranks) ranks = list()
		ranks[faculty] = rank
		if(!temporary)
			if(!base_ranks) base_ranks = list()
			base_ranks[faculty] = rank
		if(!defer_update)
			update()

/datum/psi_complexus/proc/set_cooldown(var/value)
	next_power_use = world.time + value
	ui.update_icon()

/datum/psi_complexus/proc/can_use()
	return (owner.stat == CONSCIOUS && !owner.incapacitated() && !suppressed && world.time >= next_power_use)

/datum/psi_complexus/proc/spend_power(var/value = 0)
	. = FALSE
	if(can_use())
		value = min(1, ceil(value * cost_modifier))
		if(value <= stamina)
			stamina -= value
			ui.update_icon()
			. = TRUE
		else
			backblast(abs(stamina - value))
			stamina = 0
			. = FALSE
		ui.update_icon()

/datum/psi_complexus/proc/backblast(var/value)

	// Can't backblast if you're controlling your power.
	if(!owner || suppressed)
		return FALSE

	owner << 'sound/effects/psi/power_feedback.ogg'
	to_chat(owner, "<span class='danger'><font size=3>Wild energistic feedback blasts across your psyche!</font></span>")
	stunned(value * 2)
	set_cooldown(value * 100)

	if(prob(value*10)) owner.emote("scream")

	// Your head asplode.
	owner.adjustBrainLoss(value)
	if(ishuman(owner))
		var/mob/living/carbon/human/pop = owner
		if(pop.should_have_organ(BP_BRAIN))
			var/obj/item/organ/internal/brain/sponge = pop.internal_organs_by_name[BP_BRAIN]
			if(sponge && sponge.damage >= sponge.max_damage)
				var/obj/item/organ/external/affecting = pop.get_organ(BP_HEAD)
				if(affecting && !affecting.is_stump())
					affecting.droplimb(0, DROPLIMB_BLUNT)
					if(sponge) qdel(sponge)

/datum/psi_complexus/proc/reset()
	ranks = base_ranks.Copy()
	max_stamina = initial(max_stamina)
	stamina = min(stamina, max_stamina)
	cancel()
	update()