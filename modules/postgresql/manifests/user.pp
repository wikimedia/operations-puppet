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
    String                 $user,
    String                 $ensure     = 'present',
    String                 $database   = 'template1',
    String                 $type       = 'host',
    String                 $method     = 'md5',
    Stdlib::IP::Address    $cidr       = '127.0.0.1/32',
    String                 $attrs      = '',
    Boolean                $master     = true,
    Postgresql::Privileges $privileges = {},
    Optional[String]       $password   = undef,
    Optional[Numeric]      $pgversion  = undef,
) {

    $_pgversion = $pgversion ? {
        undef   => $facts['os']['distro']['codename'] ? {
            'bullseye' => 13,
            'buster'   => 11,
            default    => fail("unsupported pgversion: ${pgversion}"),
        },
        default => $pgversion,
    }

    # Check if our user exists and store it
    $userexists = "/usr/bin/psql --tuples-only -c \'SELECT rolname FROM pg_catalog.pg_roles;\' | /bin/grep -P \'^ ${user}$\'"
    # Check if our user doesn't own databases, so we can safely drop
    $user_dbs = "/usr/bin/psql --tuples-only --no-align -c \'SELECT COUNT(*) FROM pg_catalog.pg_database JOIN pg_authid ON pg_catalog.pg_database.datdba = pg_authid.oid WHERE rolname = '${user}';\' | grep -e '^0$'"
    $pass_set = "/usr/bin/psql -c \"ALTER ROLE ${user} WITH ${attrs} PASSWORD '${password}';\""

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
    } elsif $ensure == 'absent' {
        exec { "drop_user-${name}":
            command => "/usr/bin/dropuser ${user}",
            user    => 'postgres',
            onlyif  => "${userexists} && ${user_dbs}",
        }
    }

    # Host based access configuration for user connections
    postgresql::user::hba { "Access configuration for ${name}}":
        ensure    => $ensure,
        user      => $user,
        database  => $database,
        type      => $type,
        method    => $method,
        cidr      => $cidr,
        hba_label => $name,
        pgversion => $_pgversion,
    }

    unless $privileges.empty or ! $master {
        $table_priv = 'table' in $privileges ? {
            true    => $privileges['table'],
            default => undef,
        }
        $sequence_priv = 'sequence' in $privileges ? {
            true    => $privileges['sequence'],
            default => undef,
        }
        $function_priv = 'function' in $privileges ? {
            true    => $privileges['function'],
            default => undef,
        }
        postgresql::db_grant {"grant access to ${title} on ${database}":
            db            => $database,
            pg_role       => $user,
            table_priv    => $table_priv,
            sequence_priv => $sequence_priv,
            function_priv => $function_priv,
        }
    }
}
