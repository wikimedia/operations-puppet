# analytics servers (RT-1985)

class role::analytics {
	system_role { "role::analyticss": description => "analyticss server" }

	include standard,
		admins::roots

}
