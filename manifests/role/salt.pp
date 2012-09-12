class role::salt::master {

	class { "salt::master":
		runner_dirs => "['/srv/runners']",
	}

}

class role::salt::minion {

	if ($realm == "labs") {
		$master = "virt0.wikimedia.org"
		$id = "${dc}.${domain}"
	} else {
		$master = "sockpuppet.pmtpa.wmnet"
		$id = undef
	}
	class { "salt::minion":
		master => $master,
		id => $id,
	}

}
