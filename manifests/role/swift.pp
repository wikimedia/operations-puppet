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
			shard_container_list => "wikipedia-commons-local-thumb,wikipedia-en-local-thumb",
			write_thumbs => "all",
			dont_write_thumb_list => ""
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
				rewrite_url => "http://127.0.0.1:8080/auth/v1.0",
				rewrite_user => "mw:thumb",
				rewrite_password => $passwords::swift::pmtpa-test::rewrite_password,
				rewrite_thumb_server => "upload.wikimedia.org",
				shard_containers => "none",
				shard_container_list => "",
				write_thumbs => "all",
				dont_write_thumb_list => ""
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
			cron { "swift-ganglia-report-global-stats":
				command => "/usr/local/bin/swift-ganglia-report-global-stats -u 'mw:thumbnail' -p $passwords::swift::pmtpa-prod::rewrite_password",
				user => root,
				ensure => present;
			}
		}
		class proxy inherits role::swift::pmtpa-prod {
			class { "::swift::proxy::config":
				bind_port => "80",
				proxy_address => "http://ms-fe.pmtpa.wmnet",
				num_workers => $::processorcount,
				memcached_servers => [ "ms-fe1.pmtpa.wmnet:11211", "ms-fe2.pmtpa.wmnet:11211" ],
				super_admin_key => $passwords::swift::pmtpa-prod::super_admin_key,
				rewrite_account => "AUTH_43651b15-ed7a-40b6-b745-47666abf8dfe",
				rewrite_url => "http://127.0.0.1/auth/v1.0",
				rewrite_user => "mw:thumbnail",
				rewrite_password => $passwords::swift::pmtpa-prod::rewrite_password,
				rewrite_thumb_server => "ms5.pmtpa.wmnet",
				shard_containers => "some",
				shard_container_list => "wikipedia-commons-local-thumb,wikipedia-de-local-thumb,wikipedia-en-local-thumb,wikipedia-fi-local-thumb,wikipedia-fr-local-thumb,wikipedia-he-local-thumb,wikipedia-hu-local-thumb,wikipedia-id-local-thumb,wikipedia-it-local-thumb,wikipedia-ja-local-thumb,wikipedia-ro-local-thumb,wikipedia-ru-local-thumb,wikipedia-th-local-thumb,wikipedia-tr-local-thumb,wikipedia-uk-local-thumb,wikipedia-zh-local-thumb",
				write_thumbs => "none",
				dont_write_thumb_list => ""
			}
			include ::swift::proxy
			include ::swift::proxy::monitoring
		}
		class storage inherits role::swift::pmtpa-prod {
			include ::swift::storage
			include ::swift::storage::monitoring
		}
	}
}
