class role::salt::master {

	class { "salt::master":
		runner_dirs => "['/srv/runners']",
	}

}

class role::salt::minion {

	class { "salt::minion": }

}
