# = Define: shinken::services
# Setup a shinken services definition file
define shinken::hosts(
    $ensure  = present,
    $source  = undef,
) {
    include shinken::server

    file { "/etc/shinken/services/$title.cfg":
        ensure  => $ensure,
        source  => $source,
        owner   => 'shinken',
        group   => 'shinken',
        notify  => Service['shinken'],
        require => Package['shinken']
    }
}
