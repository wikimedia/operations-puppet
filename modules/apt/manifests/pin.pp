define apt::pin($package, $pin, $priority, $ensure=present) {
	file { "/etc/apt/preferences.d/$name.pref":
		ensure	=> $ensure,
		owner   => root,
		group   => root,
		mode    => '0444',
		content => "Package: $package\nPin: $pin\nPin-Priority: $priority\n",
	}
}
