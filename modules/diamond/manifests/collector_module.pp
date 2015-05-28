# == Class diamond::collector_module
# Installs a python diamond collector module.
#
# === Parameters
# [*ensure*]
#   Specifies whether or not this Diamond python module should exist.
#   The default is 'present'.
#
# [*name*]
#   The name of the collector class. The 'Collector' suffix may be
#   omitted from the name.
#
# [*source*]
#   A Puppet file reference to the Python collector source file.
#
class diamond::collector_module(
    $ensure = 'present',
    $name,
    $source,
) {
    include ::diamond

    validate_ensure($ensure)

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
