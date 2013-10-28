# Creates a system username with associated group, random uid/gid, and /bin/false as shell
define generic::systemuser($name, $home=undef, $managehome=true, $shell="/bin/false", $groups=undef, $default_group=$name, $ensure=present) {
	# FIXME: deprecate $name parameter in favor of just using $title

	if $default_group == $name {
		group { $default_group:
			name => $default_group,
			ensure => present;
		}
	}

	user { $name:
		require => Group[$default_group],
		name => $name,
		gid => $default_group,
		home => $home ? {
			undef => "/var/lib/${name}",
			default => $home
		},
		managehome => $managehome,
		shell => $shell,
		groups => $groups,
		system => true,
		ensure => $ensure;
	}
}
