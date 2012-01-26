# misc/mgmt.pp

# IPMItool mgmt hosts

class misc::mgmthost {
	system_role { "misc::ipmimgmthost": description => "Management Host" }
	
	package { "ipmitool":
		ensure =>latest;
	}

	file { "/usr/local/sbin/mgmt":
		path => "/usr/local/sbin/mgmt",
		owner => root,
		group => root,
		mode => 0660,
		source => "puppet:///files/ipmitool/ipmi_mgmt";
	}
}
