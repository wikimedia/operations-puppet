class role::salt::masters::production {

	class { "salt::master":
		salt_runner_dirs => "['/srv/runners']",
	}

}

class role::salt::masters::labs {

	class { "salt::master":
		salt_runner_dirs => "['/srv/runners']",
		salt_peer_run => {
			"i-00000276.pmtpa.wmflabs" => ['deploy.*'],
		},
	}

}

class role::salt::minions {

	if ($realm == "labs") {
		$salt_master = "virt0.wikimedia.org"
		$salt_client_id = "${dc}.${domain}"
		$salt_grains = {
			"instanceproject" => $instanceproject,
		}
	} else {
		$salt_master = "sockpuppet.pmtpa.wmnet"
		$salt_client_id = undef
		$salt_grains = {}
	}

	class { "salt::minion":
		salt_master => $salt_master,
		salt_client_id => $salt_client_id,
		salt_grains => $salt_grains,
	}

}
