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
	}

	mount {
		"/mnt/htdocs":
			device => "10.0.5.8:/home/wikipedia/htdocs/wikipedia.org/wikistats",
			fstype => "nfs",
			options => "rw,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=10.0.5.8",
			atboot => true,
			ensure => mounted;
		"/mnt/data":
			device => "208.80.152.185:/data",
			fstype => "nfs",
			options => "rw,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.152.185",
			atboot => true,
			ensure => mounted;
		"/mnt/php":
			device => "10.0.5.8:/home/wikipedia/common/php-1.5",
			fstype => "nfs",
			options => "rw,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=10.0.5.8",
			atboot => true,
			ensure => mounted;
	}

}
