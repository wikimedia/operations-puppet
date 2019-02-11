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
    $password = undef,
    $database = 'template1',
    $type = 'host',
    $method = 'md5',
    $cidr = '127.0.0.1/32',
    $pgversion = $::lsbdistcodename ? {
        'stretch' => '9.6',
        'jessie'  => '9.4',
    },
    $attrs = '',
    $master = true,
    $ensure = 'present'
    ) {

    $pg_hba_file = "/etc/postgresql/${pgversion}/main/pg_hba.conf"

    # Check if our user exists and store it
    $userexists = "/usr/bin/psql --tuples-only -c \'SELECT rolname FROM pg_catalog.pg_roles;\' | /bin/grep -P \'^ ${user}$\'"
    # Check if our user doesn't own databases, so we can safely drop
    $user_dbs = "/usr/bin/psql --tuples-only --no-align -c \'SELECT COUNT(*) FROM pg_catalog.pg_database JOIN pg_authid ON pg_catalog.pg_database.datdba = pg_authid.oid WHERE rolname = '${user}';\' | grep -e '^0$'"
    $pass_set = "/usr/bin/psql -c \"ALTER ROLE ${user} WITH ${attrs} PASSWORD '${password}';\""

    # xpath expression to identify the user entry in pg_hba.conf
    if $type == 'local' {
        $xpath = "/files${pg_hba_file}/*[type='${type}'][database='${database}'][user='${user}'][method='${method}']"
    }
    else {
        $xpath = "/files${pg_hba_file}/*[type='${type}'][database='${database}'][user='${user}'][address='${cidr}'][method='${method}']"
    }

    if $ensure == 'present' {
        exec { "create_user-${name}":
            command => "/usr/bin/createuser --no-superuser --no-createdb --no-createrole ${user}",
            user    => 'postgres',
            unless  => $userexists,
        }

        # This will not be run on a slave as it is read-only
        if $master and $password {
            $password_md5 = md5("${password}${user}")

            exec { "pass_set-${name}":
                command   => $pass_set,
                user      => 'postgres',
                onlyif    => "/usr/bin/test -n \"\$(/usr/bin/psql -Atc \"SELECT 1 FROM pg_authid WHERE rolname = '${user}' AND rolpassword IS DISTINCT FROM 'md5${password_md5}';\")\"",
                subscribe => Exec["create_user-${name}"],
            }
        }

        if $type == 'local' {
            $changes = [
                "set 01/type \'${type}\'",
                "set 01/database \'${database}\'",
                "set 01/user \'${user}\'",
                "set 01/method \'${method}\'",
            ]
        } else {
            $changes = [
                "set 01/type \'${type}\'",
                "set 01/database \'${database}\'",
                "set 01/user \'${user}\'",
                "set 01/address \'${cidr}\'",
                "set 01/method \'${method}\'",
            ]
        }

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
