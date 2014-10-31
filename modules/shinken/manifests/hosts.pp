# = Define: shinken::hosts
# Setup a shinken hosts definition file
# FIXME: Autogenerate hosts definitions later on
define shinken::hosts(
    $ensure  = present,
    $source  = undef,
) {
    file { "/etc/shinken/hosts/$title.cfg":
        ensure  => $ensure,
        source  => $source,
        owner   => 'shinken',
        group   => 'shinken',
        notify  => Service['shinken'],
        require => Package['shinken']
    }
}
