# scripts for syncing apache changes
class apachesync {

	$scriptpath = "/usr/local/bin"

	file {
		"${scriptpath}/dologmsg":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/dologmsg";
		"${scriptpath}/sync-apache":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-apache";
		"${scriptpath}/sync-apache-simulated":
			owner => root,
			group => root,
			mode => 0555,
			ensure => link,
			target => "${scriptpath}/sync-apache";
		"${scriptpath}/apache-graceful-all":
			owner  => 'root',
			group  => 'root',
			mode   => '0554',
			source => 'puppet:///files/misc/scripts/apache-graceful-all';
		"${scriptpath}/apache-fast-test":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/apache-fast-test";
    }

}
