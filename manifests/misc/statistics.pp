# this file is for stat[0-9]/(ex-bayes) statistics servers (per ezachte - RT 2162)

class misc::statistics::base {
	system_role { "misc::statistics::base": description => "statistics server" }

	$stat_packages = [ "mc", "zip", "p7zip", "p7zip-full" ]

	package { $stat_packages:
		ensure => latest;
	}

	file {
		"/a":
			owner => ezachte,
			group => ezachte,
			mode => 0750,
			ensure => directory,
			recurse => "true";
		"/mnt/htdocs":
			ensure => directory;
		"/mnt/data":
			ensure => directory;
		"/mnt/php":
			ensure => directory;
	}

	mount {
		"/mnt/htdocs":
			device => "10.0.5.8:/home/wikipedia/htdocs/wikipedia.org/wikistats",
			fstype => "nfs",
			options => "rw,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=10.0.5.8",
			atboot => true,
			require => File['/mnt/htdocs'],
			ensure => mounted;
		"/mnt/data":
			device => "208.80.152.185:/data",
			fstype => "nfs",
			options => "rw,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.152.185",
			atboot => true,
			require => File['/mnt/data'],
			ensure => mounted;
		"/mnt/php":
			device => "10.0.5.8:/home/wikipedia/common/php-1.5",
			fstype => "nfs",
			options => "rw,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=10.0.5.8",
			atboot => true,
			require => File['/mnt/php'],
			ensure => mounted;
	}

}

# RT 2164
class misc::statistics::geoip {

	file {
		"/usr/local/share/GeoIP":
			owner => ezachte,
			group => wikidev,
			mode => 0750,
			ensure => directory;		
		"/usr/local/bin/geoiplogtag":
			owner => ezachte,
			group => wikidev,
			mode => 0750,
			source => "puppet:///files/misc/geoiplogtag",
			ensure => present;
		"/usr/local/bin/update-maxmind-geoip-lib":
			owner => ezachte,
			group => wikidev,
			mode => 0750,
			source => "puppet:///files/misc/update-maxmind-geoip-lib",
			ensure => present;
	}

	cron {
		"update-maxmind-geoip-lib":
			ensure => present,
			user => ezachte,
			command => "/usr/local/bin/update-maxmind-geoip-lib",
			monthday => 1,
			require => File['/usr/local/bin/update-maxmind-geoip-lib'];
	}
}
