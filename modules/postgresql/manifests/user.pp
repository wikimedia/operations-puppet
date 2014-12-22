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
    $pgversion = '9.1',
    $attrs = '',
    $ensure = 'present'
    ) {

    # Check if our user exists and store it
    $userexists = "/usr/bin/psql --tuples-only -c \'SELECT rolname FROM pg_catalog.pg_roles;\' | /bin/grep \'^ ${user}\'"
    # Check if our user doesn't own databases, so we can safely drop
    $user_dbs = "/usr/bin/psql --tuples-only --no-align -c \'SELECT COUNT(*) FROM pg_catalog.pg_database JOIN pg_authid ON pg_catalog.pg_database.datdba = pg_authid.oid WHERE rolname = '${user}';\' | grep -e '^0$'"
    $pass_set = "/usr/bin/psql -c \"ALTER ROLE ${user} WITH ${attrs} PASSWORD '${password}';\""

    if $ensure == 'present' {
        exec { "create_user-${name}":
            command => "/usr/bin/createuser --no-superuser --no-createdb --no-createrole ${user}",
            user    => 'postgres',
            unless  => $userexists,
        }
        # This will set the password and attributes on every puppet run. We explicitly dont
        # depend on anything to ensure consistency with configuration and that
        # password is always the one defined
        # NOTE: This has the potential of the password leaking by process
        # listing tools like ps. Need to investigate better ways of setting the
        # password .e.g. hashed with md5 in the manifest
        exec { "pass_set-${name}":
            command     => $pass_set,
            user        => 'postgres',
            onlyif      => $userexists,
        }

        $changes = [  "set 01/type \'${type}\'",
                      "set 01/database \'${database}\'",
                      "set 01/user \'${user}\'",
                      "set 01/address \'${cidr}\'",
                      "set 01/method \'${method}\'",
                ]
        augeas { "hba_create-${name}":
            context => "/files/etc/postgresql/${pgversion}/main/pg_hba.conf/",
            changes => $changes,
            onlyif  => "match /files/etc/postgresql/$pgversion/main/pg_hba.conf/*/user[. = \'${user}\'] size == 0",
            notify  => Exec['pgreload'],
        }
    } elsif $ensure == 'absent' {
        exec { "drop_user-${name}":
            command => "/usr/bin/dropuser ${user}",
            user    => 'postgres',
            onlyif  => "${userexists} && ${user_dbs}",
        }

        augeas { "hba_drop-${name}":
            context => "/files/etc/postgresql/${pgversion}/main/pg_hba.conf/",
            changes => "rm /files/etc/postgresql/$pgversion/main/pg_hba.conf/*[user = \'${user}\' ] and [database = \'${database}\'] and [ address = \'${cidr}\']",
            # only if the user exists
            onlyif  => "match /files/etc/postgresql/${pgversion}/main/pg_hba.conf/*/user[. = \'${user}\'] size > 0",
            notify  => Exec['pgreload'],
        }
    }
}
