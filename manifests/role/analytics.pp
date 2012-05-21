# analytics servers (RT-1985)

@monitor_group { "analytics-eqiad": description => "analytics servers in eqiad" }

class role::analytics {
	system_role { "role::analytics": description => "analytics server" }
	$nagios_group = "analytics-eqiad"

	include standard,
		admins::roots,
		accounts::diederik,
		accounts::dsc,
		accounts::otto

	sudo_user { [ "diederik", "dsc", "otto" ]: privileges => ['ALL = NOPASSWD: ALL'] }
}
