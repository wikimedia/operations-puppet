# = Define: shinken::config
# Setup a shinken definition file
define shinken::config(
    $ensure  = present,
    $source  = undef,
) {
    include shinken

    file { "/etc/shinken/customconfig/${title}.cfg":
        ensure  => $ensure,
        source  => $source,
        owner   => 'shinken',
        group   => 'shinken',
        notify  => Service['shinken'],
        require => Package['shinken'],
    }
}
