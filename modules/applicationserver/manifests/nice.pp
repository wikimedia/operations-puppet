## renice of ssh on applicationserver
class applicationserver::nice {
	# Adjust sshd nice level per RT #664.
	#
	# Has to be less than apache, and apache has to be nice 0 or less to be 
	# blue in ganglia. 
	#
	# Upstart requires that the job be stopped and started, not just restarted, 
	# since restarting will use the old configuration.
	#
	# In precise this can be replaced with creation of /etc/init/ssh.override

	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "12.04") >= 0 {
		file {
			"/etc/init/ssh.override": 
				owner => root,
				group => root,
				mode => 0444,
				content => "nice -10",
				ensure => present;
		}

	} else {
		exec {
			"adjust ssh nice":
				path => "/usr/sbin:/usr/bin:/sbin:/bin",
				unless => "grep -q ^nice /etc/init/ssh.conf",
				command => "echo 'nice -10' >> /etc/init/ssh.conf && (stop ssh ; start ssh)";
		}
	}
}