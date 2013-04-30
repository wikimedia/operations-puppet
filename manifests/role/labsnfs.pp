# This is a transition role - Eventually this will end up
# in LDAP once transition is over.

class role::labsnfs::client {
	$nfscluster = "labnfs.pmtpa.wmnet"

	file {
		"/etc/auto.master":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.master.erb");
	}
	file { "/etc/auto.space":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.space.erb");
	}
	file { "/etc/auto.time.home":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.time.home.erb");
	}
	file { "/etc/auto.time.project":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.time.project.erb");
	}

	upstart_job { "nfs-noidmap":
		enable => true,
		start => true,
		install => true,
	}
}

