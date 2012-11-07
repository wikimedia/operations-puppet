define apt::repository(
	$uri,
	$dist,
	$components,
	$source=true,
	$keyfile='',
	$ensure=present
) {
	$binline = "deb $uri $dist $components\n"
	$srcline = $source ? {
		true    => "deb-src $uri $dist $components\n",
		default => '',
	}

	file { "/etc/apt/sources.list.d/$name.list":
		ensure	=> $ensure,
		owner	=> root,
		group	=> root,
		mode 	=> '0444',
		content	=> "${binline}${srcline}",
	}

	if $keyfile {
		file { "/var/lib/apt/keys/$name.gpg":
			ensure	=> present,
			owner	=> root,
			group	=> root,
			mode	=> '0400',
			source	=> $keyfile,
			require	=> File['/var/lib/apt/keys']
		}

		exec { "/usr/bin/apt-key add /var/lib/apt/keys/$name.gpg":
			subscribe => File["/var/lib/apt/keys/$name.gpg"],
			refreshonly => true,
		}
	}
}
