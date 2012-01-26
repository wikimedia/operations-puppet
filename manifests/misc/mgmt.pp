# misc/mgmt.pp

# IPMItool mgmt hosts

class misc::mgmthost {
	system_role { "misc::mgmthost": description => "Management Host" }
	
	package { "IPMItool":
		ensure =>latest;
	}

	file { "/usr/sbin/mgmt":
		path => "/usr/sbin/mgmt",
		owner => root,
		group => root,
		mode => 0660,
		source => "puppet:///files/ipmitool/mgmt";
	}
}
