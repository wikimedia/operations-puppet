define pparepo($repo_string = "", $apt_key = "", $dist = "lucid", $ensure = "present") {
	$grep_for_key = "apt-key list | grep '^pub' | sed -r 's.^pub\\s+\\w+/..' | grep '^$apt_key'"

	exec { ["${name}_update_apt"]:
		command => '/usr/bin/apt-get update',
		require => File["/etc/apt/sources.list.d/${name}.list"]
	}

	case $ensure {
		present: {
			file { ["/etc/apt/sources.list.d/${name}.list"]:
				content => "deb http://ppa.launchpad.net/$repo_string/ubuntu $dist main\n",
				require => Package["python-software-properties"]
			}
			file { ["/root/${apt_key}.key"]:
				source => "puppet:///files/ppa/${apt_key}.key"
			}
			exec { "Import ${name} to apt keystore":
				path        => "/bin:/usr/bin",
				environment => "HOME=/root",
				command     => "apt-key add /root/${apt_key}.key",
				user        => "root",
				group       => "root",
				unless      => "$grep_for_key",
				logoutput   => on_failure,
				require     => File["/root/${apt_key}.key"]
			}
		}
		absent: {
			file { ["/etc/apt/sources.list.d/${name}.list"]:
				ensure => false;
			}
			exec { "Remove ${apt_key} from apt keystore":
				path    => "/bin:/usr/bin",
				environment => "HOME=/root",
				command => "apt-key del ${apt_key}",
				user    => "root",
				group   => "root",
				onlyif  => "$grep_for_key",
			}
		}
	}
}
