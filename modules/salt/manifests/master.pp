class salt::master($salt_interface="0.0.0.0", $salt_publish_port="4505", $salt_user="root", $salt_worker_threads="5", $salt_ret_port="4506", $salt_root_dir="/", $salt_pki_dir="/etc/salt/pki", $salt_cachedir="/var/cache/salt", $salt_keep_jobs="24", $salt_timeout="5", $salt_job_cache="True", $salt_runner_dirs=["/srv/runners"], $salt_external_nodes="None", $salt_renderer="yaml_jinja", $salt_failhard="False", $salt_file_roots={"base"=>["/srv/salt"]}, $salt_hash_type="md5", $salt_file_buffer_size="1048576", $salt_pillar_roots={"base"=>["/srv/pillar"]}, $salt_ext_pillar={}, $salt_reactor_root="/srv/reactors", $salt_reactor = {}, $salt_peer={}, $salt_peer_run={}, $salt_cluster_masters="[]", $salt_cluster_mode="paranoid", $salt_nodegroups={}) {

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

	file { $salt_runner_dirs:
		ensure => directory,
		mode => 0755,
		owner => root,
		group => root;
	}

	file { $salt_reactor_root:
		ensure => directory,
		mode => 0755,
		owner => root,
		group => root;
	}

}
