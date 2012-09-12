class salt::minion($master="salt", $user="root", $root_dir="/", $id="${fqdn}", $cache_jobs="False", $module_dirs="[]", $returner_dirs="[]", $returner_dirs="[]", $states_dirs="[]", $render_dirs="[]", $grains={}, $renderer="yaml_jinja", $state_verbose="False", $environment="None", $hash_type="md5") {

	package { ["salt-minion"]:
		ensure => present;
	}

	service { "salt-minion":
		ensure => running,
		enabled => true,
		requires => [Package["salt-minion"]];
	}

	file { "/etc/salt/minion":
		content => template("salt/minion.erb"),
		owner => root,
		group => root,
		mode => 0444,
		notify => Service["salt-master"],
		require => Package["salt-minion"];
	}

}
