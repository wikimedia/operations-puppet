class role::salt::masters {

	class { "salt::master":
		salt_runner_dirs => "['/srv/runners']",
	}

}

class role::salt::minions {

	if ($realm == "labs") {
		$salt_master = "virt0.wikimedia.org"
		$salt_client_id = "${dc}.${domain}"
	} else {
		$salt_master = "sockpuppet.pmtpa.wmnet"
		$salt_client_id = undef
	}
	class { "salt::minion":
		salt_master => $salt_master,
		salt_client_id => $salt_client_id,
	}

}
