# = Define: shinken::config
# Setup a shinken definition file
define shinken::config(
    $ensure  = present,
    $source  = undef,
) {
    file { "/etc/shinken/labs/${title}.cfg":
        ensure  => $ensure,
        source  => $source,
        owner   => 'shinken',
        group   => 'shinken',
    }
}
