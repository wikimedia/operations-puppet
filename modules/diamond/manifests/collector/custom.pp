# == Class: diamond::collector::custom
# Installs a custom diamond collector python plugin.
#
# === Parameters
#
# [*source*]
#   A Puppet file reference to the Python collector source file.
#
# [*ensure*]
#   Specifies whether or not to configure Diamond to use this collector.
#   May be 'present' or 'absent'. The default is 'present'.
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
        mode   => '0444',
    }
}
