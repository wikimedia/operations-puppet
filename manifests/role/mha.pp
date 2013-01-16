class mha::node {
	package { "mha4mysql-node":
		ensure => latest;
	}

	file { [ "/home/mysql", "/home/mysql/.ssh" ]:
		ensure => directory,
		owner => mysql,
		group => mysql,
		mode => 0700,
		require => User['mysql'];
	}

	file { "/home/mysql/.ssh/mysql.key":
		owner => mysql,
		group => mysql,
		mode => 0400,
		source => 'puppet:///private/ssh/mysql/mysql.key';
	}

	ssh_authorized_key {
		"mha4mysql":
			ensure => present,
			user => mysql,
			type => "ssh-rsa",
			key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDryVraiGfd0eQzV0QB/xXvgiPvpp8qt/BEqT9xWpohPNC1MevM+SMGmpimCLyvv35JDmz1DiJwJf72GKakDqWdbp/pBHitr0VV3eANpLyYiDTWir75SEF9F/WxkRTbEe/tErJc0tsksVGIm+36r3eHrrz68AkJJZVhcQMMXPx6Ye1NIy5qJ/i7cSSAxkanHlXiX+lnGMIxYUKuiVVl7kxrGDAvaLeszZKdYn8WkMH32MuL/M66ff9vBY7pGGM8MubjGMxL878hpimhTrLcmay7l4nuAMW6UUnkqufx6ArT80RWDWz5woFvyheBdVDnQZI06cJzj3WG6rWt8eG/A1SL";
	}
}

class mha::manager inherits role::coredb::config {
	include mha::node,
		passwords::misc::scripts

	$mysql_root_pass = $passwords::misc::scripts::mysql_root_pass
	$mysql_repl_pass = $passwords::misc::scripts::mysql_repl_pass

	package { "mha4mysql-manager":
		ensure => latest;
	}

	file { "/etc/mha":
		ensure => directory,
		owner => root,
		group => root,
		mode => 0700;
	}

	$shards = inline_template("<%= topology.keys %>")

	define mha_shard_config($shard={}, $site="", $altsite="") {
		file { "/etc/mha/${name}.cnf":
			owner => root,
			group => root,
			mode => 0444,
			content => template('mha/local.erb'),
		}
	}

	define mha_coredb_config {
		if $topology[$name]["primary_site"] and $topology[$name]["primary_site"] != "both" {
			# eqiad
			mha_shard_config { "${name}-eqiad":
				shard => $topology[$name],
				site => "eqiad",
				altsite => "pmtpa"
			}
			# pmtpa
			mha_shard_config { "${name}-pmtpa":
				shard => $topology[$name],
				site => "pmtpa",
				altsite => "eqiad"
			}
			# dc-switch
		}
	}

	mha_coredb_confg { $shards: }
}
