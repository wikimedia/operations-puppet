# vim: noet
@monitor_group { "swift": description => "swift servers" }

class role::swift {
	class base {
		include standard
	}

	class eqiad-prod inherits role::swift::base {
		system::role { "role::swift::eqiad-prod": description => "Swift eqiad production cluster" }
		include passwords::swift::eqiad_prod
		class { "::swift::base": hash_path_suffix => "4f93c548a5903a13", cluster_name => "eqiad-prod" }
		class ganglia_reporter inherits role::swift::eqiad-prod {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				ensure => present,
				owner  => 'root',
				group  => 'root',
				mode   => '0555',
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
			}
			# config file to hold the  password
			$password = $passwords::swift::eqiad_prod::rewrite_password
			file { "/etc/swift-ganglia-report-global-stats.conf":
				owner   => 'root',
				group   => 'root',
				mode    => '0440',
				content => template("swift/swift-ganglia-report-global-stats.conf.erb"),
			}
			cron { "swift-ganglia-report-global-stats":
				ensure  => present,
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:media' -c eqiad-prod",
				user    => root,
			}
		}
		class proxy inherits role::swift::eqiad-prod {
			class { "::swift::proxy":
				bind_port => "80",
				proxy_address => "http://ms-fe.eqiad.wmnet",
				num_workers => $::processorcount,
				memcached_servers => [ "ms-fe1001.eqiad.wmnet:11211", "ms-fe1002.eqiad.wmnet:11211", "ms-fe1003.eqiad.wmnet:11211", "ms-fe1004.eqiad.wmnet:11211" ],
				auth_backend => 'tempauth',
				super_admin_key => $passwords::swift::eqiad_prod::super_admin_key,
				rewrite_account => 'AUTH_mw',
				rewrite_password => $passwords::swift::eqiad_prod::rewrite_password,
				rewrite_thumb_server => "rendering.svc.eqiad.wmnet",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-de-local-thumb,wikipedia-en-local-thumb,wikipedia-fi-local-thumb,wikipedia-fr-local-thumb,wikipedia-he-local-thumb,wikipedia-hu-local-thumb,wikipedia-id-local-thumb,wikipedia-it-local-thumb,wikipedia-ja-local-thumb,wikipedia-ro-local-thumb,wikipedia-ru-local-thumb,wikipedia-th-local-thumb,wikipedia-tr-local-thumb,wikipedia-uk-local-thumb,wikipedia-zh-local-thumb,wikipedia-commons-local-public,wikipedia-de-local-public,wikipedia-en-local-public,wikipedia-fi-local-public,wikipedia-fr-local-public,wikipedia-he-local-public,wikipedia-hu-local-public,wikipedia-id-local-public,wikipedia-it-local-public,wikipedia-ja-local-public,wikipedia-ro-local-public,wikipedia-ru-local-public,wikipedia-th-local-public,wikipedia-tr-local-public,wikipedia-uk-local-public,wikipedia-zh-local-public,wikipedia-commons-local-temp,wikipedia-de-local-temp,wikipedia-en-local-temp,wikipedia-fi-local-temp,wikipedia-fr-local-temp,wikipedia-he-local-temp,wikipedia-hu-local-temp,wikipedia-id-local-temp,wikipedia-it-local-temp,wikipedia-ja-local-temp,wikipedia-ro-local-temp,wikipedia-ru-local-temp,wikipedia-th-local-temp,wikipedia-tr-local-temp,wikipedia-uk-local-temp,wikipedia-zh-local-temp,wikipedia-commons-local-transcoded,wikipedia-de-local-transcoded,wikipedia-en-local-transcoded,wikipedia-fi-local-transcoded,wikipedia-fr-local-transcoded,wikipedia-he-local-transcoded,wikipedia-hu-local-transcoded,wikipedia-id-local-transcoded,wikipedia-it-local-transcoded,wikipedia-ja-local-transcoded,wikipedia-ro-local-transcoded,wikipedia-ru-local-transcoded,wikipedia-th-local-transcoded,wikipedia-tr-local-transcoded,wikipedia-uk-local-transcoded,wikipedia-zh-local-transcoded,global-data-math-render",
				backend_url_format => "sitelang"
			}
			class { '::swift::proxy::monitoring':
				host => 'ms-fe.eqiad.wmnet',
			}
		}
		class storage inherits role::swift::eqiad-prod {
			include ::swift::storage
			include ::swift::storage::monitoring
		}
	}
	class esams-prod inherits role::swift::base {
		system::role { "role::swift::esams-prod": description => "Swift esams production cluster" }
		include passwords::swift::esams_prod
		class { "::swift::base": hash_path_suffix => "a0af6563d361f968", cluster_name => "esams-prod" }
		class ganglia_reporter inherits role::swift::esams-prod {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				ensure => present,
				owner  => 'root',
				group  => 'root',
				mode   => '0555',
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
			}
			# config file to hold the password
			$password = $passwords::swift::esams_prod::rewrite_password
			file { "/etc/swift-ganglia-report-global-stats.conf":
				owner   => 'root',
				group   => 'root',
				mode    => '0440',
				content => template("swift/swift-ganglia-report-global-stats.conf.erb"),
			}
			cron { "swift-ganglia-report-global-stats":
				ensure  => present,
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:media' -c esams-prod",
				user    => root,
			}
		}
		class proxy inherits role::swift::esams-prod {
			class { "::swift::proxy":
				bind_port => "80",
				proxy_address => "http://ms-fe.esams.wmnet",
				num_workers => $::processorcount,
				memcached_servers => [ "ms-fe3001.esams.wmnet:11211", "ms-fe3002.esams.wmnet:11211" ],
				auth_backend => 'tempauth',
				super_admin_key => $passwords::swift::esams_prod::super_admin_key,
				rewrite_account => 'AUTH_mw',
				rewrite_password => $passwords::swift::esams_prod::rewrite_password,
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_container_list => "",
				backend_url_format => "asis"
			}
			class { '::swift::proxy::monitoring':
				host => 'ms-fe.esams.wmnet',
			}
		}
		class storage inherits role::swift::esams-prod {
			include ::swift::storage
			include ::swift::storage::monitoring
		}
	}

}

# class role::swift::labs
#
#  Classes for a simple swift cluster on labs hosts.
#
#  You'll want one node with role::swift::labs::proxy
#  And two or more nodes using  role::swift::labs::storage
#
#  The storage nodes should also have some big partitions mounted in /srv/swift-storage.
#    The simplest way to get that is via role::labs::lvm::swift.
#
#  These classes presume that the ring files will come from the puppet master in /var/lib/puppet/volatile.
#  I'm handling that by using project-wide puppetmaster to hold the files, but you could also just drop
#  those files onto virt1000...  in either case, here's how to make the rings:
#
#  $  # make empty rings  with two copies of each file:
#  $ swift-ring-builder account.builder create 18 2 1
#  $ swift-ring-builder container.builder create 18 2 1
#  $ swift-ring-builder object.builder create 18 2 1
#  $
#  $  # Tell rings about each storage box:
#  $ export ZONE=<incrementing zone number, starting with 1>
#  $ export STORAGE_LOCAL_NET_IP=<ip of storage node>
#  $ export DEVICE=<mount point inside /srv/swift-storage.  If you're using role::labs::lvm::swift then this is 'swiftstore'>
#  $ export WEIGHT=100 <I think this is a percentage?>
#  $ swift-ring-builder account.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6002/$DEVICE $WEIGHT
#  $ swift-ring-builder container.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6002/$DEVICE $WEIGHT
#  $ swift-ring-builder object.builder add z$ZONE-$STORAGE_LOCAL_NET_IP:6002/$DEVICE $WEIGHT
#  $  # repeat for each hostbox, incremeanting ZONE each time
#  $  # Then, rebalance...
#  swift-ring-builder account.builder rebalance
#  swift-ring-builder container.builder rebalance
#  swift-ring-builder object.builder rebalance

# Make sure the rings are served up so that puppet on the swift nodes is
# installing them.  Also chown and chgrp /srv/swift-storage/* to 'swift'
# on all storage nodes.
#
# Finally, start the services everywhere:
#
# $ swift-init all start
#
# And restart memcached on the proxy:
#
# $ server memcached restart
#
# That's it!  To test you can do things like this:
#
# $ # upload:
# $ swift -A http://$PROXY_LOCAL_NET_IP:80/auth/v1.0 -U admin:admin -K <password from labs private> upload <containername> <filename>
# $ # download:
# $ swift -A http://$PROXY_LOCAL_NET_IP:80/auth/v1.0 -U admin:admin -K <password from labs private> download <containername>
#
class role::swift::labs inherits role::swift::base {
	if $::swift_proxy_hostname == undef {
		fail('$swift_proxy_hostname must be set to the FQDN of your proxy host.')
	}

	system::role { "role::swift::labs": description => "Swift labs test production" }
	include passwords::swift::eqiad_prod
	class { "::swift::base": hash_path_suffix => "d2e8dd1aecea6e71", cluster_name => "labs_swift" }
	class ganglia_reporter inherits role::swift::labs {
		# one host per cluster should report global stats
		file { "/usr/local/bin/swift-ganglia-report-global-stats":
			ensure => present,
			owner  => 'root',
			group  => 'root',
			mode   => '0555',
			source => "puppet:///files/swift/swift-ganglia-report-global-stats",
		}
		# config file to hold the  password
		$password = $passwords::swift::eqiad_labs::rewrite_password
		file { "/etc/swift-ganglia-report-global-stats.conf":
			owner   => 'root',
			group   => 'root',
			mode    => '0440',
			content => template("swift/swift-ganglia-report-global-stats.conf.erb"),
		}
		cron { "swift-ganglia-report-global-stats":
			ensure  => present,
			command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:media' -c labs",
			user    => root,
		}
	}
	class proxy inherits role::swift::labs {
		class { "::swift::proxy":
			bind_port => "80",
			proxy_address => "http://${swift_proxy_hostname}",
			num_workers => $::processorcount,
			memcached_servers => [ "${swift_proxy_hostname}:11211" ],
			auth_backend => 'tempauth',
			super_admin_key => $passwords::swift::eqiad_prod::super_admin_key,
			rewrite_account => 'AUTH_mw',
			rewrite_password => $passwords::swift::eqiad_prod::rewrite_password,
			rewrite_thumb_server => "rendering.svc.eqiad.wmnet",
			shard_container_list => "wikipedia-commons-local-thumb,wikipedia-de-local-thumb,wikipedia-en-local-thumb,wikipedia-fi-local-thumb,wikipedia-fr-local-thumb,wikipedia-he-local-thumb,wikipedia-hu-local-thumb,wikipedia-id-local-thumb,wikipedia-it-local-thumb,wikipedia-ja-local-thumb,wikipedia-ro-local-thumb,wikipedia-ru-local-thumb,wikipedia-th-local-thumb,wikipedia-tr-local-thumb,wikipedia-uk-local-thumb,wikipedia-zh-local-thumb,wikipedia-commons-local-public,wikipedia-de-local-public,wikipedia-en-local-public,wikipedia-fi-local-public,wikipedia-fr-local-public,wikipedia-he-local-public,wikipedia-hu-local-public,wikipedia-id-local-public,wikipedia-it-local-public,wikipedia-ja-local-public,wikipedia-ro-local-public,wikipedia-ru-local-public,wikipedia-th-local-public,wikipedia-tr-local-public,wikipedia-uk-local-public,wikipedia-zh-local-public,wikipedia-commons-local-temp,wikipedia-de-local-temp,wikipedia-en-local-temp,wikipedia-fi-local-temp,wikipedia-fr-local-temp,wikipedia-he-local-temp,wikipedia-hu-local-temp,wikipedia-id-local-temp,wikipedia-it-local-temp,wikipedia-ja-local-temp,wikipedia-ro-local-temp,wikipedia-ru-local-temp,wikipedia-th-local-temp,wikipedia-tr-local-temp,wikipedia-uk-local-temp,wikipedia-zh-local-temp,wikipedia-commons-local-transcoded,wikipedia-de-local-transcoded,wikipedia-en-local-transcoded,wikipedia-fi-local-transcoded,wikipedia-fr-local-transcoded,wikipedia-he-local-transcoded,wikipedia-hu-local-transcoded,wikipedia-id-local-transcoded,wikipedia-it-local-transcoded,wikipedia-ja-local-transcoded,wikipedia-ro-local-transcoded,wikipedia-ru-local-transcoded,wikipedia-th-local-transcoded,wikipedia-tr-local-transcoded,wikipedia-uk-local-transcoded,wikipedia-zh-local-transcoded,global-data-math-render",
			backend_url_format => "sitelang"
		}
		class { '::swift::proxy::monitoring':
			host => $swift_proxy_hostname,
		}
	}
	class storage inherits role::swift::labs {
		include ::swift::storage
		include ::swift::storage::monitoring
	}
}
