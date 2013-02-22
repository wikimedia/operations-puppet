@monitor_group { "swift": description => "swift servers" }

class role::swift {
	class base {
		$cluster = "swift"
		$nagios_group = "swift"

		include standard
		# TODO: pull in iptables rules here, or in the classes below
	}
	
	class eqiad-test inherits role::swift::base {
		system_role { "role::swift::eqiad-test": description => "Swift testing cluster" }
		system_role { "swift-cluster::eqiad-test": description => "Swift testing cluster", ensure => absent }
		include passwords::swift::eqiad-test
		# The eqiad test cluster runs proxy and storage on the same hosts
		class { "::swift::base": hash_path_suffix => "fbf7dab9c04865cd", cluster_name => "eqiad-test" }
		class { "::swift::proxy::config":
			bind_port => "8080",
			proxy_address => "http://msfe-test.wikimedia.org:8080",
			memcached_servers => [ "copper.wikimedia.org:11211", "magnesium.wikimedia.org:11211", "zinc.wikimedia.org:11211" ],
			num_workers => $::processorcount * 2,
			super_admin_key => $passwords::swift::eqiad-test::super_admin_key,
			rewrite_account => "AUTH_854f8c66-63b6-4965-8b6c-5b2ccfe79aa8",
			rewrite_thumb_server => "ms5.pmtpa.wmnet",
			shard_containers => "some",
			shard_container_list => "wikipedia-commons-local-thumb,wikipedia-en-local-thumb",
			backend_url_format => "asis"
		}
		include ::swift::storage
		include	::swift::proxy

		# FIXME: split these iptables rules apart into common, proxy, and
		# storage so storage nodes aren't listening on http, etc.
		# load iptables rules to allow http-alt, memcached, rsync, swift protocols, ssh, and all ICMP traffic.
		include	::swift::iptables
	}
	
	class pmtpa-test inherits role::swift::base {
		system_role { "role::swift::pmtpa-test": description => "Swift testing cluster" }
		system_role { "swift-cluster::pmtpa-test": description => "Swift testing cluster", ensure => absent }
		include passwords::swift::pmtpa-test
		class { "::swift::base": hash_path_suffix => "fbf7dab9c04865cd", cluster_name => "pmtpa-test" }
		class proxy inherits role::swift::pmtpa-test {
			class { "::swift::proxy::config":
				bind_port => "8080",
				proxy_address => "http://msfe-pmtpa-test.wikimedia.org:8080",
				num_workers => $::processorcount * 2,
				memcached_servers => [ "owa1.wikimedia.org:11211", "owa2.wikimedia.org:11211", "owa3.wikimedia.org:11211" ],
				super_admin_key => $passwords::swift::pmtpa-test::super_admin_key,
				rewrite_account => "AUTH_205b4c23-6716-4a3b-91b2-5da36ce1d120",
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_containers => "none",
				shard_container_list => "",
				backend_url_format => "asis"
			}
			include ::swift::proxy
		}
		class storage inherits role::swift::pmtpa-test {
			include ::swift::storage
		}

		# FIXME: split these iptables rules apart into common, proxy, and
		# storage so storage nodes aren't listening on http, etc.
		# load iptables rules to allow http-alt, memcached, rsync, swift protocols, ssh, and all ICMP traffic.
		include ::swift::iptables
	}

	class pmtpa-prod inherits role::swift::base {
		system_role { "role::swift::pmtpa-prod": description => "Swift pmtpa production cluster" }
		system_role { "swift-cluster::pmtpa-prod": description => "Swift pmtpa production cluster", ensure => absent }
		include passwords::swift::pmtpa-prod
		class { "::swift::base": hash_path_suffix => "bd51d755d4c53773", cluster_name => "pmtpa-prod" }
		class ganglia_reporter inherits role::swift::pmtpa-prod {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				path => "/usr/local/bin/swift-ganglia-report-global-stats",
				mode => 0555,
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
				ensure => present;
			}
			# config file to hold the password
			$password = $passwords::swift::pmtpa-prod::rewrite_password
			file { "/etc/swift-ganglia-report-global-stats.conf":
				mode => 0440,
				owner => root,
				group => root,
				content => template("swift/swift-ganglia-report-global-stats.conf.erb");
			}
			cron { "swift-ganglia-report-global-stats":
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:thumb' -c pmtpa-prod",
				user => root,
				ensure => present;
			}
		}
		class proxy inherits role::swift::pmtpa-prod {
			class { "::swift::proxy::config":
				bind_port => "80",
				proxy_address => "http://ms-fe.pmtpa.wmnet",
				num_workers => $::processorcount,
				memcached_servers => [ "ms-fe1.pmtpa.wmnet:11211", "ms-fe2.pmtpa.wmnet:11211", "ms-fe3.pmtpa.wmnet:11211", "ms-fe4.pmtpa.wmnet:11211" ],
				super_admin_key => $passwords::swift::pmtpa-prod::super_admin_key,
				rewrite_account => "AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe",
				rewrite_thumb_server => "rendering.svc.eqiad.wmnet",
				shard_containers => "some",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-de-local-thumb,wikipedia-en-local-thumb,wikipedia-fi-local-thumb,wikipedia-fr-local-thumb,wikipedia-he-local-thumb,wikipedia-hu-local-thumb,wikipedia-id-local-thumb,wikipedia-it-local-thumb,wikipedia-ja-local-thumb,wikipedia-ro-local-thumb,wikipedia-ru-local-thumb,wikipedia-th-local-thumb,wikipedia-tr-local-thumb,wikipedia-uk-local-thumb,wikipedia-zh-local-thumb,wikipedia-commons-local-public,wikipedia-de-local-public,wikipedia-en-local-public,wikipedia-fi-local-public,wikipedia-fr-local-public,wikipedia-he-local-public,wikipedia-hu-local-public,wikipedia-id-local-public,wikipedia-it-local-public,wikipedia-ja-local-public,wikipedia-ro-local-public,wikipedia-ru-local-public,wikipedia-th-local-public,wikipedia-tr-local-public,wikipedia-uk-local-public,wikipedia-zh-local-public,wikipedia-commons-local-temp,wikipedia-de-local-temp,wikipedia-en-local-temp,wikipedia-fi-local-temp,wikipedia-fr-local-temp,wikipedia-he-local-temp,wikipedia-hu-local-temp,wikipedia-id-local-temp,wikipedia-it-local-temp,wikipedia-ja-local-temp,wikipedia-ro-local-temp,wikipedia-ru-local-temp,wikipedia-th-local-temp,wikipedia-tr-local-temp,wikipedia-uk-local-temp,wikipedia-zh-local-temp,wikipedia-commons-local-transcoded,wikipedia-de-local-transcoded,wikipedia-en-local-transcoded,wikipedia-fi-local-transcoded,wikipedia-fr-local-transcoded,wikipedia-he-local-transcoded,wikipedia-hu-local-transcoded,wikipedia-id-local-transcoded,wikipedia-it-local-transcoded,wikipedia-ja-local-transcoded,wikipedia-ro-local-transcoded,wikipedia-ru-local-transcoded,wikipedia-th-local-transcoded,wikipedia-tr-local-transcoded,wikipedia-uk-local-transcoded,wikipedia-zh-local-transcoded,global-data-math-render",
				backend_url_format => "sitelang"
			}
			include ::swift::proxy
			include ::swift::proxy::monitoring
		}
		class storage inherits role::swift::pmtpa-prod {
			include ::swift::storage
			include ::swift::storage::monitoring
		}
	}
	class eqiad-prod inherits role::swift::base {
		system_role { "role::swift::eqiad-prod": description => "Swift eqiad production cluster" }
		system_role { "swift-cluster::eqiad-prod": description => "Swift eqiad production cluster", ensure => absent }
		include passwords::swift::eqiad-prod
		class { "::swift::base": hash_path_suffix => "4f93c548a5903a13", cluster_name => "eqiad-prod" }
		class ganglia_reporter inherits role::swift::eqiad-prod {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				path => "/usr/local/bin/swift-ganglia-report-global-stats",
				mode => 0555,
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
				ensure => present;
			}
			# config file to hold the password
			$password = $passwords::swift::eqiad-prod::rewrite_password
			file { "/etc/swift-ganglia-report-global-stats.conf":
				mode => 0440,
				owner => root,
				group => root,
				content => template("swift/swift-ganglia-report-global-stats.conf.erb");
			}
			cron { "swift-ganglia-report-global-stats":
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:thumb' -c eqiad-prod",
				user => root,
				ensure => present;
			}
		}
		class proxy inherits role::swift::eqiad-prod {
			class { "::swift::proxy::config":
				bind_port => "80",
				proxy_address => "http://ms-fe.eqiad.wmnet",
				num_workers => $::processorcount,
				memcached_servers => [ "ms-fe1001.eqiad.wmnet:11211", "ms-fe1002.eqiad.wmnet:11211", "ms-fe1003.eqiad.wmnet:11211", "ms-fe1004.eqiad.wmnet:11211" ],
				super_admin_key => $passwords::swift::eqiad-prod::super_admin_key,
				rewrite_account => "AUTH_60c17d04-176d-4717-861b-90b20917b1c0",
				rewrite_thumb_server => "rendering.svc.eqiad.wmnet",
				shard_containers => "some",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-de-local-thumb,wikipedia-en-local-thumb,wikipedia-fi-local-thumb,wikipedia-fr-local-thumb,wikipedia-he-local-thumb,wikipedia-hu-local-thumb,wikipedia-id-local-thumb,wikipedia-it-local-thumb,wikipedia-ja-local-thumb,wikipedia-ro-local-thumb,wikipedia-ru-local-thumb,wikipedia-th-local-thumb,wikipedia-tr-local-thumb,wikipedia-uk-local-thumb,wikipedia-zh-local-thumb,wikipedia-commons-local-public,wikipedia-de-local-public,wikipedia-en-local-public,wikipedia-fi-local-public,wikipedia-fr-local-public,wikipedia-he-local-public,wikipedia-hu-local-public,wikipedia-id-local-public,wikipedia-it-local-public,wikipedia-ja-local-public,wikipedia-ro-local-public,wikipedia-ru-local-public,wikipedia-th-local-public,wikipedia-tr-local-public,wikipedia-uk-local-public,wikipedia-zh-local-public,wikipedia-commons-local-temp,wikipedia-de-local-temp,wikipedia-en-local-temp,wikipedia-fi-local-temp,wikipedia-fr-local-temp,wikipedia-he-local-temp,wikipedia-hu-local-temp,wikipedia-id-local-temp,wikipedia-it-local-temp,wikipedia-ja-local-temp,wikipedia-ro-local-temp,wikipedia-ru-local-temp,wikipedia-th-local-temp,wikipedia-tr-local-temp,wikipedia-uk-local-temp,wikipedia-zh-local-temp,wikipedia-commons-local-transcoded,wikipedia-de-local-transcoded,wikipedia-en-local-transcoded,wikipedia-fi-local-transcoded,wikipedia-fr-local-transcoded,wikipedia-he-local-transcoded,wikipedia-hu-local-transcoded,wikipedia-id-local-transcoded,wikipedia-it-local-transcoded,wikipedia-ja-local-transcoded,wikipedia-ro-local-transcoded,wikipedia-ru-local-transcoded,wikipedia-th-local-transcoded,wikipedia-tr-local-transcoded,wikipedia-uk-local-transcoded,wikipedia-zh-local-transcoded,global-data-math-render",
				backend_url_format => "sitelang"
			}
			include ::swift::proxy
			include ::swift::proxy::monitoring
		}
		class storage inherits role::swift::eqiad-prod {
			include ::swift::storage
			include ::swift::storage::monitoring
		}
	}
	class pmtpa-labs inherits role::swift::base {
		system_role { "role::swift::pmtpa-labs": description => "Swift pmtpa labs cluster" }
		#include passwords::swift::pmtpa-labs #passwords inline because they're not secret in labs
		class { "::swift::base": hash_path_suffix => "a222ef4c988d7ba2", cluster_name => "pmtpa-labs" }
		class ganglia_reporter inherits role::swift::pmtpa-labs {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				path => "/usr/local/bin/swift-ganglia-report-global-stats",
				mode => 0555,
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
				ensure => present;
			}
			cron { "swift-ganglia-report-global-stats":
				command => "/usr/local/bin/swift-ganglia-report-global-stats -u 'mw:thumbnail' -p userpassword -c pmtpa-labs",
				user => root,
				ensure => present;
			}
		}
		class proxy inherits role::swift::pmtpa-labs {
			class { "::swift::proxy::config":
				bind_port => "80",
				proxy_address => "http://swift-fe1.pmtpa.wmflabs",
				num_workers => $::processorcount * 2,
				memcached_servers => [ "127.0.0.1:11211" ],
				super_admin_key => "thiskeyissuper",
				rewrite_account => "AUTH_f80b5643-4597-407f-94f5-d2cc051805cf",
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_containers => "none",
				shard_container_list => "",
				backend_url_format => "asis"
			}
			include ::swift::proxy
		}
		class storage inherits role::swift::pmtpa-labs {
			include ::swift::storage
		}
	}
	class pmtpa-labsupgrade inherits role::swift::base {
		system_role { "role::swift::pmtpa-labsupgrade": description => "Swift pmtpa labs upgradecluster" }
		#include passwords::swift::pmtpa-labs #passwords inline because they're not secret in labs
		class { "::swift::base": hash_path_suffix => "e67dec345de3173a", cluster_name => "pmtpa-labsupgrade" }
		class ganglia_reporter inherits role::swift::pmtpa-labsupgrade {
			# one host per cluster should report global stats
			file { "/usr/local/bin/swift-ganglia-report-global-stats":
				path => "/usr/local/bin/swift-ganglia-report-global-stats",
				mode => 0555,
				source => "puppet:///files/swift/swift-ganglia-report-global-stats",
				ensure => present;
			}
			# config file to hold the password (which isn't secret in labs)
			$password = "userpassword"
			file { "/etc/swift-ganglia-report-global-stats.conf":
				mode => 0440,
				owner => root,
				group => root,
				content => template("swift/swift-ganglia-report-global-stats.conf.erb");
			}
			cron { "swift-ganglia-report-global-stats":
				command => "/usr/local/bin/swift-ganglia-report-global-stats -C /etc/swift-ganglia-report-global-stats.conf -u 'mw:thumbnail' -c pmtpa-labsupgrade",
				user => root,
				ensure => present;
			}
		}
		class proxy inherits role::swift::pmtpa-labsupgrade {
			class { "::swift::proxy::config":
				bind_port => "80",
				proxy_address => "http://su-fe1.pmtpa.wmflabs",
				num_workers => $::processorcount * 2,
				memcached_servers => [ "10.4.0.167:11211", "10.4.0.175:11211" ],
				super_admin_key => "notsoseekritkey",
				rewrite_account => "AUTH_28e2c57d-458d-4d9e-b543-17a395f632f8",
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_containers => "none",
				shard_container_list => "",
				backend_url_format => "asis"
			}
			include ::swift::proxy
		}
		class storage inherits role::swift::pmtpa-labsupgrade {
			include ::swift::storage
		}
	}
}
