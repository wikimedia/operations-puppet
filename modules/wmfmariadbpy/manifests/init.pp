# SPDX-License-Identifier: Apache-2.0
# Profile to setup and configure wmfmariadbpy libraries and
# utilities.
class wmfmariadbpy (
    Wmfmariadbpy::Role         $role          = 'db',
    Hash[String, Stdlib::Port] $section_ports = {},
) {

    file{'/etc/wmfmariadbpy':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file{'/etc/wmfmariadbpy/section_ports.csv':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('wmfmariadbpy/section_ports.csv.erb'),
    }

    # Always install this explicitly, so that other puppet modules can refer to it.
    ensure_packages('python3-wmfmariadbpy')

    $extra_packages = $role ? {
        'admin'   => ['wmfmariadbpy-admin'],
        'library' => [],
        default   => ['wmfmariadbpy-common'],
    }
    ensure_packages($extra_packages)
}
