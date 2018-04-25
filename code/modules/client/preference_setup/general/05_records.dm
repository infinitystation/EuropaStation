/datum/category_item/player_setup_item/general/records
	name = "Records"
	sort_order = 5

/datum/category_item/player_setup_item/general/records/load_character(var/savefile/S)
	S["med_record"]				>> pref.med_record
	S["sec_record"]				>> pref.sec_record
	S["gen_record"]				>> pref.gen_record

/datum/category_item/player_setup_item/general/records/save_character(var/savefile/S)
	S["med_record"]				<< pref.med_record
	S["sec_record"]				<< pref.sec_record
	S["gen_record"]				<< pref.gen_record

/datum/category_item/player_setup_item/general/records/content(var/mob/user)
	if(jobban_isbanned(user, "Records"))
		. += "<span class='danger'>You are banned from using character records.</span><br>"
	else
		. += "Medical Records:<br>"
		. += "<a href='?src=\ref[src];set_medical_records=1'>[TextPreview(pref.med_record,40)]</a><br><br>"
		. += "Employment Records:<br>"
		. += "<a href='?src=\ref[src];set_general_records=1'>[TextPreview(pref.gen_record,40)]</a><br><br>"
		. += "Security Records:<br>"
		. += "<a href='?src=\ref[src];set_security_records=1'>[TextPreview(pref.sec_record,40)]</a><br>"

/datum/category_item/player_setup_item/general/records/OnTopic(var/href,var/list/href_list, var/mob/user)
	if(href_list["set_medical_records"])
		var/new_medical = input(user,"Enter medical information here.","Character Preference", html_decode(pref.med_record)) as message|null
		new_medical = sanitize(new_medical, MAX_PAPER_MESSAGE_LEN, extra = 0)
		new_medical = sanitize_a2u(new_medical)
		if(!isnull(new_medical) && !jobban_isbanned(user, "Records") && CanUseTopic(user))
			pref.med_record = new_medical
		return TOPIC_REFRESH

	else if(href_list["set_general_records"])
		var/new_general = input(user,"Enter employment information here.","Character Preference", html_decode(pref.gen_record)) as message|null
		new_general = sanitize(new_general, MAX_PAPER_MESSAGE_LEN, extra = 0)
		new_general = sanitize_a2u(new_general)
		if(!isnull(new_general) && !jobban_isbanned(user, "Records") && CanUseTopic(user))
			pref.gen_record = new_general
		return TOPIC_REFRESH

	else if(href_list["set_security_records"])
		var/sec_medical = input(user,"Enter security information here.","Character Preference", html_decode(pref.sec_record)) as message|null
		sec_medical = sanitize(sec_medical, MAX_PAPER_MESSAGE_LEN, extra = 0)
		sec_medical = sanitize_a2u(sec_medical)
		if(!isnull(sec_medical) && !jobban_isbanned(user, "Records") && CanUseTopic(user))
			pref.sec_record = sec_medical
		return TOPIC_REFRESH

	return ..()
