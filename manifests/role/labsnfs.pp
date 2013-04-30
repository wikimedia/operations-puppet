# This is a transition role - Eventually this will end up
# in LDAP once transition is over.

class role::labsnfs::client {
	$nfscluster = "labnfs.pmtpa.wmnet"

	exec { "/sbin/initctl start nfs-noidmap":
		refreshonly => true
	}

	file {
		"/etc/auto.master":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.master.erb");
		"/etc/auto.space":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.space.erb");
		"/etc/auto.time.home":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.time.home.erb");
		"/etc/auto.time.project":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			content => template("labsnfs/auto.time.project.erb");
		"/etc/init/nfs-noidmap.conf":
			ensure => file,
			owner => root,
			group => root,
			mode => 0444,
			notify => Exec["/sbin/initctl start nfs-noidmap"],
			source => "puppet:///files/labsnfs/nfs-noidmap.conf";
	}
}

