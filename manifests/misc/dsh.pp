# Standard installation of dsh (Dancer's distributed shell)

class misc::dsh {
	package { "dsh":
		ensure => present
	}
	include files
	
	class files {
		file {
			"/etc/dsh/group":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/dsh/group",
				recurse => true;
			"/etc/dsh/dsh.conf":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/dsh/dsh.conf";
		}
	}
}

# Checks that this host belongs to dsh group(s)
define dsh_groups( $groups = [] ) {
	$groups_string = join( $groups, ' ' )

	monitor_service { "dsh":
		description => 'dsh groups',
		check_command => "check_dsh_groups!$groups_string",
	}
}
