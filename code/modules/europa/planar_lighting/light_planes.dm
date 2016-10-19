/obj/screen/plane
	name = ""
	screen_loc = "CENTER"
	blend_mode = BLEND_MULTIPLY

/obj/screen/plane/New(var/client/C)
	..()
	if(istype(C)) C.screen += src
	verbs.Cut()

/obj/screen/plane/master
	appearance_flags = NO_CLIENT_COLOR | PLANE_MASTER | RESET_TRANSFORM | RESET_COLOR | RESET_ALPHA
	color = list(null,null,null,"#0000","#000f")  // Completely black.
	plane = MASTER_PLANE

/obj/screen/plane/dark
	blend_mode = BLEND_ADD
	plane = DARK_PLANE // Just below the master plane.
	icon = 'icons/planar_lighting/over_dark.dmi'
	alpha = 5
	appearance_flags = RESET_TRANSFORM | RESET_COLOR | RESET_ALPHA

/obj/screen/plane/dark/New()
	..()
	var/matrix/M = matrix()
	M.Scale(world.view*2.2)
	transform = M

/image/lightmask
	name = ""
	screen_loc = "CENTER"
	blend_mode = BLEND_MULTIPLY

/image/darkmask
	blend_mode = BLEND_SUBTRACT
	mouse_opacity = 0
	plane = DARK_PLANE
	icon = 'icons/planar_lighting/over_dark.dmi'
	appearance_flags = KEEP_TOGETHER