# statistics servers (per ezachte - RT 2162)

class role::statistics {
	system_role { "role::statistics": description => "statistics server" }

	include standard,
		admins::roots,
		misc::statistics::user,
		backup::client,  # amanda backups
		generic::packages::git-core,
		misc::statistics::base,
		base::packages::emacs
}
