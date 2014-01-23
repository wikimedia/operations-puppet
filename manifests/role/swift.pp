# vim: noet
@monitor_group { "swift": description => "swift servers" }

class role::swift {
	class base {
		$cluster = "swift"
		$nagios_group = "swift"

		include standard
	}
	
	class pmtpa-prod inherits role::swift::base {
		system::role { "role::swift::pmtpa-prod": description => "Swift pmtpa production cluster" }
		include passwords::swift::pmtpa-prod
		class { "::swift::base": hash_path_suffix => "bd51d755d4c53773", cluster_name => "pmtpa-prod" }
		class ganglia_reporter inherits role::swift::pmtpa-prod {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				ensure => present,
				owner  => 'root',
				group  => 'root',
				mode   => '0555',
				source => 'puppet:///files/swift/swift-ganglia-report-global-stats',
			}
			# config file to hold the password
			$password = $passwords::swift::pmtpa-prod::rewrite_password
			file { "/etc/swift-ganglia-report-global-stats.conf":
				owner   => 'root',
				group   => 'root',
				mode    => '0440',
				content => template("swift/swift-ganglia-report-global-stats.conf.erb"),
			}
			cron { "swift-ganglia-report-global-stats":
				ensure  => present,
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:thumb' -c pmtpa-prod",
				user    => root,
			}
		}
		class proxy inherits role::swift::pmtpa-prod {
			class { "::swift::proxy":
				bind_port => "80",
				proxy_address => "http://ms-fe.pmtpa.wmnet",
				num_workers => $::processorcount,
				memcached_servers => [ "ms-fe1.pmtpa.wmnet:11211", "ms-fe2.pmtpa.wmnet:11211", "ms-fe3.pmtpa.wmnet:11211", "ms-fe4.pmtpa.wmnet:11211" ],
				statsd_host => '10.64.0.18',  # tungsten.eqiad.wmnet
				statsd_metric_prefix => "swift.pmtpa.${::hostname}",
				auth_backend => 'swauth',
				super_admin_key => $passwords::swift::pmtpa-prod::super_admin_key,
				rewrite_account => "AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe",
				rewrite_password => $passwords::swift::pmtpa-prod::rewrite_password,
				rewrite_thumb_server => "rendering.svc.eqiad.wmnet",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-de-local-thumb,wikipedia-en-local-thumb,wikipedia-fi-local-thumb,wikipedia-fr-local-thumb,wikipedia-he-local-thumb,wikipedia-hu-local-thumb,wikipedia-id-local-thumb,wikipedia-it-local-thumb,wikipedia-ja-local-thumb,wikipedia-ro-local-thumb,wikipedia-ru-local-thumb,wikipedia-th-local-thumb,wikipedia-tr-local-thumb,wikipedia-uk-local-thumb,wikipedia-zh-local-thumb,wikipedia-commons-local-public,wikipedia-de-local-public,wikipedia-en-local-public,wikipedia-fi-local-public,wikipedia-fr-local-public,wikipedia-he-local-public,wikipedia-hu-local-public,wikipedia-id-local-public,wikipedia-it-local-public,wikipedia-ja-local-public,wikipedia-ro-local-public,wikipedia-ru-local-public,wikipedia-th-local-public,wikipedia-tr-local-public,wikipedia-uk-local-public,wikipedia-zh-local-public,wikipedia-commons-local-temp,wikipedia-de-local-temp,wikipedia-en-local-temp,wikipedia-fi-local-temp,wikipedia-fr-local-temp,wikipedia-he-local-temp,wikipedia-hu-local-temp,wikipedia-id-local-temp,wikipedia-it-local-temp,wikipedia-ja-local-temp,wikipedia-ro-local-temp,wikipedia-ru-local-temp,wikipedia-th-local-temp,wikipedia-tr-local-temp,wikipedia-uk-local-temp,wikipedia-zh-local-temp,wikipedia-commons-local-transcoded,wikipedia-de-local-transcoded,wikipedia-en-local-transcoded,wikipedia-fi-local-transcoded,wikipedia-fr-local-transcoded,wikipedia-he-local-transcoded,wikipedia-hu-local-transcoded,wikipedia-id-local-transcoded,wikipedia-it-local-transcoded,wikipedia-ja-local-transcoded,wikipedia-ro-local-transcoded,wikipedia-ru-local-transcoded,wikipedia-th-local-transcoded,wikipedia-tr-local-transcoded,wikipedia-uk-local-transcoded,wikipedia-zh-local-transcoded,global-data-math-render",
				backend_url_format => "sitelang"
			}
			class { '::swift::proxy::monitoring':
				host => 'ms-fe.pmtpa.wmnet',
			}

		}
		class storage inherits role::swift::pmtpa-prod {
			include ::swift::storage
			include ::swift::storage::monitoring
		}
	}
	class eqiad-prod inherits role::swift::base {
		system::role { "role::swift::eqiad-prod": description => "Swift eqiad production cluster" }
		include passwords::swift::eqiad-prod
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
			# config file to hold the password
			$password = $passwords::swift::eqiad-prod::rewrite_password
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
				statsd_host => '10.64.0.18',  # tungsten.eqiad.wmnet
				statsd_metric_prefix => "swift.eqiad.${::hostname}",
				statsd_sample_rate_factor => 0.01,
				auth_backend => 'tempauth',
				super_admin_key => $passwords::swift::eqiad-prod::super_admin_key,
				rewrite_account => 'AUTH_mw',
				rewrite_password => $passwords::swift::eqiad-prod::rewrite_password,
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
	class pmtpa-labs inherits role::swift::base {
		system::role { "role::swift::pmtpa-labs": description => "Swift pmtpa labs cluster" }
		#include passwords::swift::pmtpa-labs #passwords inline because they're not secret in labs
		class { "::swift::base": hash_path_suffix => "a222ef4c988d7ba2", cluster_name => "pmtpa-labs" }
		class ganglia_reporter inherits role::swift::pmtpa-labs {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				ensure => present,
				path => "/usr/local/bin/swift-ganglia-report-global-stats",
				mode => 0555,
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
			}
			cron { "swift-ganglia-report-global-stats":
				ensure  => present,
				command => "/usr/local/bin/swift-ganglia-report-global-stats -u 'mw:thumbnail' -p userpassword -c pmtpa-labs",
				user    => root,
			}
		}
		class proxy inherits role::swift::pmtpa-labs {
			class { "::swift::proxy":
				bind_port => "80",
				proxy_address => "http://swift-fe1.pmtpa.wmflabs",
				num_workers => $::processorcount * 2,
				memcached_servers => [ "127.0.0.1:11211" ],
				auth_backend => 'swauth',
				super_admin_key => "thiskeyissuper",
				rewrite_account => "AUTH_f80b5643-4597-407f-94f5-d2cc051805cf",
				rewrite_password => $passwords::swift::pmtpa-labs::rewrite_password,
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_container_list => "",
				backend_url_format => "asis"
			}
		}
		class storage inherits role::swift::pmtpa-labs {
			include ::swift::storage
		}
	}
	class pmtpa-labsupgrade inherits role::swift::base {
		system::role { "role::swift::pmtpa-labsupgrade": description => "Swift pmtpa labs upgradecluster" }
		#include passwords::swift::pmtpa-labs #passwords inline because they're not secret in labs
		class { "::swift::base": hash_path_suffix => "e67dec345de3173a", cluster_name => "pmtpa-labsupgrade" }
		class ganglia_reporter inherits role::swift::pmtpa-labsupgrade {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				ensure => present,
				path => "/usr/local/bin/swift-ganglia-report-global-stats",
				mode => 0555,
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
			}
			# config file to hold the password (which isn't secret in labs)
			$password = "userpassword"
			file { "/etc/swift-ganglia-report-global-stats.conf":
				mode => 0440,
				owner => root,
				group => root,
				content => template("swift/swift-ganglia-report-global-stats.conf.erb"),
			}
			cron { "swift-ganglia-report-global-stats":
				ensure  => present,
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:thumbnail' -c pmtpa-labsupgrade",
				user    => root,
			}
		}
		class proxy inherits role::swift::pmtpa-labsupgrade {
			class { "::swift::proxy":
				bind_port => "80",
				proxy_address => "http://su-fe1.pmtpa.wmflabs",
				num_workers => $::processorcount * 2,
				memcached_servers => [ "10.4.0.167:11211", "10.4.0.175:11211" ],
				super_admin_key => "notsoseekritkey",
				auth_backend => 'swauth',
				rewrite_account => "AUTH_28e2c57d-458d-4d9e-b543-17a395f632f8",
				rewrite_password => $passwords::swift::pmtpa-labsupgrade::rewrite_password,
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_container_list => "",
				backend_url_format => "asis"
			}
		}
		class storage inherits role::swift::pmtpa-labsupgrade {
			include ::swift::storage
		}
	}
}
