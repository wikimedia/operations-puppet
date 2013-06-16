# nfs.pp

# Virtual resource for the monitoring server
#@monitor_group { "nfs": description => "NFS" }

class nfs::common {
	package { nfs-common:
		ensure => latest;
	}
}

class nfs::home {
	include nfs::common,
		nfs::home::wikipedia

	# Class admins tests whether Mount["/home"] is defined
	mount { "/home":
		device => "10.0.5.8:/home",
		fstype => "nfs",
		name => "/home",
		options => "bg,tcp,rsize=8192,wsize=8192,timeo=14,intr",
		ensure => mounted;
	}
}

# Historical /home/wikipedia
class nfs::home::wikipedia {

	case $::realm {
		'production': {
			require nfs::home
			file { "/home/wikipedia":
				mode   => 0755,
				owner  => root,
				group  => root,
				ensure => directory;
			}
		} # /production
		'labs': {
			systemuser { 'wikipediauser':
				name => 'wikipedia',
				home => '/home/wikipedia'
			}

			file { "/home/wikipedia":
				ensure => directory,
				require => Systemuser['wikipediauser']
			}
		}
	}

}

class nfs::upload {
	include nfs::common

	# NetApp migration
	class { 'nfs::netapp::originals':
		ensure => absent,
	}
	class { 'nfs::netapp::thumbs':
		ensure => absent,
	}

	file { [ "/mnt/thumbs", "/mnt/upload6" ]:
			ensure => directory;
	}

	mount {
		"/mnt/thumbs":
			device => "ms5.pmtpa.wmnet:/export/thumbs",
			fstype => "nfs",
			name => "/mnt/thumbs",
			options => "bg,soft,tcp,timeo=14,intr,nfsvers=3",
			require => File["/mnt/thumbs"],
			ensure => absent;
		"/mnt/upload6":
			device => "ms7.pmtpa.wmnet:/export/upload",
			fstype => "nfs",
			name => "/mnt/upload6",
			options => "bg,soft,udp,rsize=8192,wsize=8192,timeo=14,intr,nfsvers=3",
			require => File["/mnt/upload6"],
			ensure => absent;
		"/mnt/upload5":
			device => "ms1.wikimedia.org:/export/upload",
			fstype => "nfs",
			name => "/mnt/upload5",
			ensure => absent;
	}
}

# Setup /mnt/{thumbs,upload6} as symlink to /data/project/<subdir>
class nfs::upload::labs {
	file {
		"/mnt/thumbs":
			ensure => absent;

		"/mnt/upload6":
			ensure => link,
			target => "/data/project/upload6";

		# Production started using upload7 on its config on mediawiki-config:158e6540
		"/mnt/upload7":
			ensure => link,
			target => "/data/project/upload7";
	}
}

class nfs::data {
	include nfs::common

	file { [ "/mnt/data" ]:
		ensure => directory;
	}

	mount {
		"/mnt/data":
			device => "dataset2.wikimedia.org:/data",
			fstype => "nfs",
			name => "/mnt/data",
			options => "bg,hard,tcp,rsize=8192,wsize=8192,intr,nfsvers=3",
			require => File["/mnt/data"],
			remounts => false,
			ensure => mounted;
	}
}
