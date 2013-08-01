class base::sysctl {
	if ($::lsbdistid == "Ubuntu") and ($::lsbdistrelease != "8.04") {
		exec { "/sbin/start procps":
			path => "/bin:/sbin:/usr/bin:/usr/sbin",
			refreshonly => true;
		}

		# FIXME: *never* source a file from a module
		sysctlfile { 'wikimedia-base':
			source => 'puppet:///modules/sysctlfile/50-wikimedia-base.conf',
			number_prefix => '50',
			ensure => $ensure,
			notify => Exec["/sbin/start procps"],
		}

		# Disable IPv6 privacy extensions, we rather not see our servers hide
		file { "/etc/sysctl.d/10-ipv6-privacy.conf":
			ensure => absent
		}
	} else {
	    # FIXME: this is a super ugly hack but the sysctlfile module is broken,
	    # relying on a definition to be defined in base.pp to actually work
		exec { "/sbin/start procps":
			command => '/bin/true',
			refreshonly => true,
		}
	}
}
