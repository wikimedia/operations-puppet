# Class: shinken::realm
#
# Populate a shinken realm with possible subrealms
define shinken::realm(
    $realm_name = $title,
    $members = undef,
    $default = 0,
) {
    file { "/etc/shinken/realms/${title}.cfg":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('shinken/realm.cfg.erb'),
        tag     => 'shinken-realm',
    }
}
