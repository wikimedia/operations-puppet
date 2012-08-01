## renice of ssh on applicationserver
class applicationserver::nice {
	# Has to be less than apache, and apache has to be nice 0 or less to be
	# blue in ganglia.

	if $::lsbdistid == "Ubuntu" and versioncmp($::lsbdistrelease, "12.04") >= 0 {
		file {
			"/etc/init/ssh.override":
				owner => root,
				group => root,
				mode => 0444,
				content => "nice -10",
				ensure => present;
		}
	}
}