class role::salt::masters::production {

	$salt_file_roots = {"base"=>["/srv/salt"]}
	$salt_pillar_roots = {"base"=>["/srv/pillars"]}
	$salt_module_roots = {"base"=>["/srv/salt/_modules"]}

	class { "salt::master":
		salt_runner_dirs => ["/srv/runners"],
		salt_peer_run => {
			"tin.eqiad.wmnet" => ['deploy.*'],
		},
		salt_file_roots => $salt_file_roots,
		salt_pillar_roots => $salt_pillar_roots,
		salt_worker_threads => "25",
	}

	salt::master_environment{ "base":
		salt_file_roots => $salt_file_roots,
		salt_pillar_roots => $salt_pillar_roots,
		salt_module_roots => $salt_module_roots,
	}

}

class role::salt::masters::labs {

	$salt_file_roots = {"base"=>["/srv/salt"]}
	$salt_pillar_roots = {"base"=>["/srv/pillars"]}
	$salt_module_roots = {"base"=>["/srv/salt/_modules"]}

	class { "salt::master":
		salt_runner_dirs => ["/srv/runners"],
		salt_peer_run => {
			"i-00000276.pmtpa.wmflabs" => ['deploy.*'],
		},
		salt_file_roots => $salt_file_roots,
		salt_pillar_roots => $salt_pillar_roots,
		salt_worker_threads => "50",
	}

	salt::master_environment{ "base":
		salt_file_roots => $salt_file_roots,
		salt_pillar_roots => $salt_pillar_roots,
		salt_module_roots => $salt_module_roots,
	}

}

class role::salt::minions {

	if ($realm == "labs") {
		$salt_master = "virt0.wikimedia.org"
		$salt_client_id = "${dc}.${domain}"
		$salt_grains = {
			"instanceproject" => $instanceproject,
			"realm" => $realm,
			"site" => $site,
			"cluster" => $cluster,
		}
		$salt_master_finger = "5d:07:fb:28:21:60:fb:db:46:ff:e8:1c:91:a2:1a:f9"
	} else {
		$salt_master = "sockpuppet.pmtpa.wmnet"
		$salt_client_id = undef
		$salt_grains = {
			"realm" => $realm,
			"site" => $site,
			"cluster" => $cluster,
		}
		$salt_master_finger = "e6:f5:71:f5:b0:5c:45:7b:b1:f2:1d:06:4e:b9:98:9f"
	}

	class { "salt::minion":
		salt_master => $salt_master,
		salt_client_id => $salt_client_id,
		salt_grains => $salt_grains,
		salt_master_finger => $salt_master_finger,
		salt_dns_check => "False",
	}

}
