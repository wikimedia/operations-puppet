# == Class diamond::collector::custom
# Installs a custom diamond collector python plugin.
#
define diamond::collector::custom(
    $source,
    $ensure = 'present'
) {
    file { "/usr/share/diamond/collectors/${name}":
        ensure => ensure_directory($ensure),
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { "/usr/share/diamond/collectors/${name}/${name}.py":
        ensure => $ensure,
        source => $source,
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }
}
