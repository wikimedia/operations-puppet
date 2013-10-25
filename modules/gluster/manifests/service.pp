class gluster::service {
	include gluster::client,
		gluster::server

	service { "glusterfs-server":
		enable => true,
		ensure => running,
		require => [Package["glusterfs-server"], File["/etc/init.d/glusterfs-server"], File["/etc/default/glusterd"], File["/etc/glusterfs/glusterd.vol"]];
	}
	file {
		"/etc/init.d/glusterfs-server":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///modules/gluster/glusterfs-server",
			require => [Package["glusterfs-server"]];
		"/etc/default/glusterd":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/gluster/glusterd-default",
			require => [Package["glusterfs-server"]];
		"/etc/glusterfs/glusterd.vol":
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///modules/gluster/glusterd.vol",
			require => [Package["glusterfs-server"]];
		"/etc/init/glusterfs-server.conf":
			ensure => absent;
	}

}
