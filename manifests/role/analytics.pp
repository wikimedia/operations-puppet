# analytics servers (RT-1985)

class role::analytics {
	system_role { "role::analytics": description => "analytics server" }

	include standard,
		admins::roots

}
