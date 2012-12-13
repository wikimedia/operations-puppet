class salt::minion($salt_master="salt", $salt_master_port="4506", $salt_user="root", $salt_root_dir="/", $salt_pki_dir="/etc/salt/pki", $salt_client_id="${fqdn}", $salt_cache_jobs="False", $salt_module_dirs="[]", $salt_returner_dirs="[]", $salt_returner_dirs="[]", $salt_states_dirs="[]", $salt_render_dirs="[]", $salt_grains={}, $salt_renderer="yaml_jinja", $salt_state_verbose="False", $salt_environment="None", $salt_hash_type="md5", $salt_master_finger="", $salt_dns_check="True") {

	package { ["salt-minion"]:
		ensure => present;
	}

	service { "salt-minion":
		ensure => running,
		enable => true,
		require => [Package["salt-minion"]];
	}

	file { "/etc/salt/minion":
		content => template("salt/minion.erb"),
		owner => root,
		group => root,
		mode => 0444,
		notify => Service["salt-minion"],
		require => Package["salt-minion"];
	}

}
