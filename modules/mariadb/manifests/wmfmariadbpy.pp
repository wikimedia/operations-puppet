# Class to setup and configure wmfmariadbpy libraries and
# utilities.
class mariadb::wmfmariadbpy (
    Enum['admin', 'db'] $role,
    Hash[String, Stdlib::Port] $section_ports,
) {
    file { '/etc/mysql/section_ports.csv':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('mariadb/section_ports.csv.erb'),
    }

    case $role {
        'admin': {
            require_package('wmfmariadbpy-admin')
        }
        'db': {
            require_package('wmfmariadbpy-common')
        }
        default: {
            fail("Unknown wmfmariadbpy role: '${role}'")
        }
    }
}

