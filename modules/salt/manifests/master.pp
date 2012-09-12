class salt::master($interface="0.0.0.0", $publish_port="4505", $user="root", $worker_threads="5", $ret_port="4506", $root_dir="/", $pki_dir="/etc/salt/pki", $cachedir="/var/cache/salt", $keep_jobs="24", $timeout="5", $job_cache="True", $runner_dirs="[]", $external_nodes="None", $renderer="yaml_jinja", $failhard="False", $file_roots={"base"=>"/srv/salt"}, $hash_type="md5", $file_buffer_size="1048576", $pillar_roots={"base"=>"/srv/pillar"}, $ext_pillar={}, $peer={}, $peer_run={}, $cluster_masters="[]", $cluster_mode="paranoid", $nodegroups={}) {

	package { ["salt-master"]:
		ensure => present;
	}

	service { "salt-master":
		ensure => running,
		enable => true,
		require => [Package["salt-master"]];
	}

	file { "/etc/salt/master":
		content => template("salt/master.erb"),
		owner => root,
		group => root,
		mode => 0444,
		notify => Service["salt-master"],
		require => [Package["salt-master"]];
	}

}
