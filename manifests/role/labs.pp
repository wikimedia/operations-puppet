#
# This is a nice generic place to make project-specific roles with a sane
# naming scheme.
#

class role::labs::tools::bastion {
	include role::labsnfs::client # temporary measure

	$grid_master = "tools-master.pmtpa.wmflabs"
	system_role { "role::labs::tools::bastion": description => "Tool Labs bastion" }
	class { 'toollabs::bastion':
		gridmaster => $grid_master,
	}
}

class role::labs::tools::execnode {
	include role::labsnfs::client # temporary measure

	$grid_master = "tools-master.pmtpa.wmflabs"
	system_role { "role::labs::tools::execnode": description => "Tool Labs execution host" }
	class { 'toollabs::execnode':
		gridmaster => $grid_master,
	}
}

class role::labs::tools::master {
	include role::labsnfs::client # temporary measure

	$grid_master = "tools-master.pmtpa.wmflabs"
	system_role { "role::labs::tools::master": description => "Tool Labs gridengine master" }
	class { 'toollabs::master':
		gridmaster => $grid_master,
	}
}

class role::labs::tools::shadow {
	include role::labsnfs::client # temporary measure

	$grid_master = "tools-master.pmtpa.wmflabs"
	system_role { "role::labs::tools::shadow": description => "Tool Labs gridengine shadow (backup) master" }
	class { 'toollabs::shadow':
		gridmaster => $grid_master,
	}
}

class role::labs::tools::webserver {
	include role::labsnfs::client # temporary measure

	$grid_master = "tools-master.pmtpa.wmflabs"
	system_role { "role::labs::tools::webserver": description => "Tool Labs webserver" }
	class { 'toollabs::webserver':
		gridmaster => $grid_master,
	}
}

class role::labs::tools::webproxy {
	include role::labsnfs::client # temporary measure

	$grid_master = "tools-master.pmtpa.wmflabs"
	system_role { "role::labs::tools::webproxy": description => "Tool Labs web proxy" }
	class { 'toollabs::webproxy':
		gridmaster => $grid_master,
	}
}

