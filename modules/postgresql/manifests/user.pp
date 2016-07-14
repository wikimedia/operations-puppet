#
# Definition: postgresql::user
#
# This definition provides a way to manage postgresql users.
#
# Parameters:
#
# Actions:
#   Create/drop user
#
# Requires:
#   Class postgresql::server
#
# Sample Usage:
#  postgresql::user { 'test@host.example.com':
#    ensure   => 'absent',
#    user     => 'test',
#    password => 'pass',
#    cidr     => '127.0.0.1/32',
#    type     => 'host',
#    method   => 'trust',
#    database => 'template1',
#  }
#
# Based upon https://github.com/uggedal/puppet-module-postgresql
#
define postgresql::user(
    $user,
    $password,
    $database = 'template1',
    $type = 'host',
    $method = 'md5',
    $cidr = '127.0.0.1/32',
    $pgversion = $::lsbdistcodename ? {
        jessie  => '9.4',
        precise => '9.1',
        trusty  => '9.3',
    },
    $attrs = '',
    $ensure = 'present'
    ) {

    $password_hashed = postgresql_password($user, $password)

    $pg_hba_file = "/etc/postgresql/${pgversion}/main/pg_hba.conf"

    # Check if our user exists and store it
    $userexists = "/usr/bin/psql --tuples-only -c \'SELECT rolname FROM pg_catalog.pg_roles;\' | /bin/grep \'^ ${user}\'"
    # Check if our user doesn't own databases, so we can safely drop
    $user_dbs = "/usr/bin/psql --tuples-only --no-align -c \'SELECT COUNT(*) FROM pg_catalog.pg_database JOIN pg_authid ON pg_catalog.pg_database.datdba = pg_authid.oid WHERE rolname = '${user}';\' | grep -e '^0$'"
    $pass_set = "/usr/bin/psql -c \"ALTER ROLE ${user} WITH ENCRYPTED PASSWORD '${password_hashed}';\""
    $pass_is_set = "/usr/bin/psql --tuples-only -c \"SELECT usename FROM pg_catalog.pg_shadow WHERE usename='${user}' and passwd='${password_hashed}';\" | /bin/grep \'^ ${user}\'"
    $attrs_set = "/usr/bin/psql -c \"ALTER ROLE ${user} WITH ${attrs};\""

    # xpath expression to identify the user entry in pg_hba.conf
    $xpath = "/files${pg_hba_file}/*[type='${type}'][database='${database}'][user='${user}'][address='${cidr}'][method='${method}']"

    if $ensure == 'present' {
        exec { "create_user-${name}":
            command => "/usr/bin/createuser --no-superuser --no-createdb --no-createrole ${user}",
            user    => 'postgres',
            unless  => $userexists,
            notify  => [ Exec["attrs_set-${name}"] ],
        }

        exec { "pass_set-${name}":
            command => $pass_set,
            user    => 'postgres',
            onlyif  => $userexists,
            unless  => $pass_is_set,
            require => [ Exec["create_user-${name}"] ],
        }

        exec { "attrs_set-${name}":
            command     => $attrs_set,
            user        => 'postgres',
            onlyif      => $userexists,
            refreshonly => true,
        }

        $changes = [
            "set 01/type \'${type}\'",
            "set 01/database \'${database}\'",
            "set 01/user \'${user}\'",
            "set 01/address \'${cidr}\'",
            "set 01/method \'${method}\'",
        ]

        augeas { "hba_create-${name}":
            context => "/files${pg_hba_file}/",
            changes => $changes,
            onlyif  => "match ${xpath} size == 0",
            notify  => Exec['pgreload'],
        }
    } elsif $ensure == 'absent' {
        exec { "drop_user-${name}":
            command => "/usr/bin/dropuser ${user}",
            user    => 'postgres',
            onlyif  => "${userexists} && ${user_dbs}",
        }

        augeas { "hba_drop-${name}":
            context => "/files${pg_hba_file}/",
            changes => "rm ${xpath}",
            # only if the user exists
            onlyif  => "match ${xpath} size > 0",
            notify  => Exec['pgreload'],
        }
    }
}
