# nfs.pp

# Virtual resource for the monitoring server
#@monitor_group { "nfs": description => "NFS" }

class nfs::common {
	package { nfs-common:
		ensure => latest;
	}
}

class nfs::server {

	include nfs::common

	package { nfs-kernel-server:
		ensure => latest;
	}

	if $static_nfs {
		file {
			'/etc/default/nfs-common':
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/nfs/nfs-common",
				ensure => present,
				require => Package["nfs-common"];
			'/etc/default/nfs-kernel-server':
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/nfs/nfs-kernel-server",
				ensure => present,
				require => Package["nfs-kernel-server"];
			'/etc/default/quota':
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/nfs/quota",
				ensure => present,
				require => Package["nfs-kernel-server"];
			'/etc/modprobe.d/lockd.conf':
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/nfs/lockd.conf",
				ensure => present,
				require => Package["nfs-kernel-server"];
		}

	}

}

class nfs::home {
	include nfs::common

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
		'production': { require nfs::home }
		'labs': { systemuser { 'wikipediauser': name => 'wikipedia', home => '/home/wikipedia' } }
	}

	file { "/home/wikipedia":
		mode   => 0755,
		owner  => root,
		group  => root,
		ensure => directory;
	}
}

class nfs::upload {
	include nfs::common

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
			ensure => mounted;
		"/mnt/upload6":
			device => "ms7.pmtpa.wmnet:/export/upload",
			fstype => "nfs",
			name => "/mnt/upload6",
			options => "bg,soft,udp,rsize=8192,wsize=8192,timeo=14,intr,nfsvers=3",
			require => File["/mnt/upload6"],
			ensure => mounted;
		"/mnt/upload5":
			device => "ms1.wikimedia.org:/export/upload",
			fstype => "nfs",
			name => "/mnt/upload5",
			ensure => absent;
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
	
