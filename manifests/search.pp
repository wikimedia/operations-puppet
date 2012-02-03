# search.pp

# Virtual resource for the monitoring server
@monitor_group { "lucene": description => "pmtpa search servers" }

class search::sudo {
	file { "/etc/sudoers.d/search":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.search",
		ensure => present;
	}
}

class search::php {
	file { "/etc/php5/apache2/php.ini":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/php/php.ini.appserver";
	}
}

class search::jvm {
	# FIXME: build replacement packages
	
	# These packages are no longer available in Lucid
	if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") < 0 {
		package { ia32-sun-java6-bin:
			ensure => latest;
		}

		$jvm = $hostname ? {
			/search(11|13)/	=> "/usr/lib/jvm/java-6-openjdk/jre/bin/java",
			default		=> "/usr/lib/jvm/ia32-java-6-sun/jre/bin/java",
		}

		exec { jvm-alternatives:
			command => "/usr/sbin/update-alternatives --set java $jvm"
		}
	}
}

class search::monitoring {
	if ! $search_indexer {
		monitor_service { "lucene": description => "Lucene", check_command => "check_lucene", retries => 6 }
	}
}

class search::indexer {

	include passwords::lucene
	$lucene_oai_pass = $passwords::lucene::oai_pass

	package { nfs-common:
                ensure => latest;
        }

	file { "/etc/lsearch.conf":
		owner => root,                                                                                                                                                 
                group => root,                                                                                                                                                 
                mode => 0644,
		content => template("lucene/lsearch.conf.erb"),
		ensure => present;
	}

	file { "/etc/default/rsync":
                owner => root,
                group => root,
                mode => 0644,
                source => "puppet:///files/rsync/rsync.default",
                ensure => present;
        }

	file { "/etc/rsyncd.conf":
                owner => root,
                group => root,
                mode => 0644,
                source => "puppet:///files/rsync/rsyncd.conf.searchidx",
                ensure => present;
        }

	service { "rsync" :
		ensure => running,
		enable => true,
		hasstatus => false,
		require => [ File["/etc/default/rsync"], File["/etc/rsyncd.conf"] ]
	}
}
