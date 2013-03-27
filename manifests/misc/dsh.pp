# Standard installation of dsh (Dancer's distributed shell)

class misc::dsh {
	package { "dsh":
		ensure => present
	}

	file {
		"/etc/dsh/group":
			owner => root,
			group => root,
			mode => "a=rX",
			source => "puppet:///files/dsh/group",
			recurse => true;
		"/etc/dsh/dsh.conf":
			owner => root,
			group => root,
			mode => "a=r",
			source => "puppet:///files/dsh/dsh.conf";
	}
}
