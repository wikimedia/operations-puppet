# misc/mgmt.pp

# IPMItool mgmt hosts

class misc::management::ipmi {
	system_role { "misc::management::ipmi": description => "IPMI Management Host" }
	
	package { "ipmitool":
		ensure =>latest;
	}

	file { "/usr/local/sbin/ipmi_mgmt":
		path => "/usr/local/sbin/ipmi_mgmt",
		owner => root,
		group => root,
		mode => 0550,
		source => "puppet:///files/ipmitool/ipmi_mgmt";
	}
}
