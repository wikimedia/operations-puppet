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
			rewrite_url => "http://127.0.0.1:8080/auth/v1.0",
			rewrite_user => "test:tester",
			rewrite_password => $passwords::swift::eqiad-test::rewrite_password,
			rewrite_thumb_server => "ms5.pmtpa.wmnet",
			shard_containers => "some",
			shard_container_list => "wikipedia-commons-local-thumb,wikipedia-en-local-thumb"
		}
		include ::swift::storage
		include ::swift::proxy
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
				rewrite_url => "http://127.0.0.1:8080/auth/v1.0",
				rewrite_user => "mw:thumb",
				rewrite_password => $passwords::swift::pmtpa-test::rewrite_password,
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_containers => "none",
				shard_container_list => ""
			}
			include ::swift::proxy
		}
		class storage inherits role::swift::pmtpa-test {
			include ::swift::storage
		}
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
			cron { "swift-ganglia-report-global-stats":
				command => "/usr/local/bin/swift-ganglia-report-global-stats -u 'mw:thumbnail' -p $passwords::swift::pmtpa-prod::rewrite_password -c pmtpa-prod",
				user => root,
				ensure => present;
			}
		}
		class proxy inherits role::swift::pmtpa-prod {
			class { "::swift::proxy::config":
				bind_port => "80",
				proxy_address => "http://ms-fe.pmtpa.wmnet",
				num_workers => $::processorcount * 2,
				memcached_servers => [ "ms-fe1.pmtpa.wmnet:11211", "ms-fe2.pmtpa.wmnet:11211" ],
				super_admin_key => $passwords::swift::pmtpa-prod::super_admin_key,
				rewrite_account => "AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe",
				rewrite_url => "http://127.0.0.1/auth/v1.0",
				rewrite_user => "mw:thumbnail",
				rewrite_password => $passwords::swift::pmtpa-prod::rewrite_password,
				rewrite_thumb_server => "ms5.pmtpa.wmnet",
				shard_containers => "some",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-en-local-thumb"
			}
			include ::swift::proxy
		}
		class storage inherits role::swift::pmtpa-prod {
			include ::swift::storage
		}
	}
	class pmtpa-labs inherits role::swift::base {
		system_role { "role::swift::pmtpa-labs": description => "Swift pmtpa labs cluster" }
		system_role { "swift-cluster::pmtpa-labs": description => "Swift pmtpa labs cluster", ensure => absent }
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
				rewrite_account => "AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe",
				rewrite_url => "http://127.0.0.1/auth/v1.0",
				rewrite_user => "mw:thumbnail",
				rewrite_password => "userpassword",
				rewrite_thumb_server => "ms5.pmtpa.wmnet",
				shard_containers => "some",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-en-local-thumb"
			}
			include ::swift::proxy
		}
		class storage inherits role::swift::pmtpa-labs {
			include ::swift::storage
		}
	}
}
