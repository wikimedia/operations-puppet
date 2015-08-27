# == Class: phabricator::arcrc
#
# === Parameters
#
# [*rootdir*]
#    Phabricator base directory
# [*user*]
#    User who's arcrc file we're writing
# [*cert*]
#    Their secret cert

define phabricator::arcrc(
	$rootdir = '/',
	$user    = '',
	$cert    = '',
) {
	file { "${rootdir}/arcrc":
		ensure  => directory,
		require => File["${rootdir}"],
	}

    file { "${rootdir}/arcrc/${user}.arcrc":
        ensure  => 'file',
        content => template('phabricator/arcrc.erb'),
        require => File["${rootdir}/arcrc"],
    }
}
