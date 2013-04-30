# == Define: ipython::profile
#
# Creates an IPython configuration profile.
#
# === Parameters
#
# [*user*]
#   Create a configuration profile for this user. Defaults to 'ipython'.
#
# [*ipythondir*]
#   Use this folder as the base IPYTHONDIR. Defaults to '/srv/ipython'.
#
# [*parallel*]
#   If true, include the config files for parallel computing apps.
#   False by default.
#
define ipython::profile(
	$user       = $ipython::user,
	$ipythondir = $ipython::ipythondir,
	$parallel   = false
) {
	include ipython

	$options = $parallel ? {
		true    => '--parallel',
		default => '',
	}

	exec { "ipython profile ${title}":
		command     => "/usr/bin/ipython profile create ${title} ${options}",
		creates     => "${ipythondir}/profile_${title}",
		environment => "IPYTHONDIR=${ipythondir}",
		require     => Package['ipython'],
		user        => $user,
	}
}
