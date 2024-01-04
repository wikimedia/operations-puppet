# @summary This definition provides a way to manage postgresql users.
# @param user the user to configure
# @param ensure ensurable parameter
# @param database the database to configure the user with
# @param type the type of user access
# @param cidr the cidr address that hosts are allowed to come from
# @param attrs additional attributes of the user
# @param allowed_hosts a list of hosts allowed to use this user
# @param master is this the postgress master
# @param privileges a list of privileges to configure for the user
# @param pgversion the postgress version
# @param password the password to configure
# @param method the method to use
#
# @example
#  postgresql::user { 'test@host.example.com':
#    ensure   => 'absent',
#    user     => 'test',
#    password => 'pass',
#    cidr     => '127.0.0.1/32',
#    type     => 'host',
#    database => 'template1',
#  }
#
# Based upon https://github.com/uggedal/puppet-module-postgresql
#
define postgresql::user (
    String                        $user,
    String                        $ensure        = 'present',
    String                        $database      = 'template1',
    String                        $type          = 'host',
    Boolean                       $master        = true,
    Postgresql::Privileges        $privileges    = {},
    Array[Stdlib::Fqdn]           $allowed_hosts = [],
    Optional[Stdlib::IP::Address] $cidr          = undef,
    Optional[String[1]]           $attrs         = undef,
    Optional[String]              $password      = undef,
    Optional[Numeric]             $pgversion     = undef,
    Optional[String[1]]           $method        = undef,
) {
    $_pgversion = $pgversion ? {
        undef   => $facts['os']['distro']['codename'] ? {
            'bookworm' => 15,
            'bullseye' => 13,
            'buster'   => 11,
            default    => fail("unsupported pgversion: ${pgversion}"),
        },
        default => $pgversion,
    }
    # lint:ignore:version_comparison
    $_method = $method.lest || { ($_pgversion >= 15).bool2str('scram-sha-256', 'md5') }
    # lint:endignore

    $cidrs = ($allowed_hosts.map |$_host| {
        dnsquery::lookup($_host).map |$answer| {
            $answer ? {
                Stdlib::IP::Address::V4::Nosubnet => "${answer}/32",
                Stdlib::IP::Address::V6::Nosubnet => "${answer}/64",
                default                           => fail("unexpected answer (${answer}) for ${_host}"),
            }
        }
    # We have to do sort after the filter as sort cant compare String with :undef
    } + $cidr).flatten.unique.filter |$x| { $x =~ String }.sort
    # backwards compatibility to default to 127.0.0.1 if nothing else set
    $_cidrs = $cidrs.empty ? {
        true    => ['127.0.0.1/32'],
        default => $cidrs,
    }

    # Check if our user exists and store it
    $userexists = "/usr/bin/psql --tuples-only -c \'SELECT rolname FROM pg_catalog.pg_roles;\' | /bin/grep -P \'^ ${user}$\'"
    # Check if our user doesn't own databases, so we can safely drop
    $user_dbs = "/usr/bin/psql --tuples-only --no-align -c \'SELECT COUNT(*) FROM pg_catalog.pg_database JOIN pg_authid ON pg_catalog.pg_database.datdba = pg_authid.oid WHERE rolname = '${user}';\' | grep -e '^0$'"
    $pass_set = "/usr/bin/psql -c \"ALTER ROLE ${user} WITH ${attrs} PASSWORD '${password}';\""

    # Starting with Bookworm passwords are hashed with salted Scram-SHA256. The user is still tested for existance,
    # but no password changes are supported T326325
    $password_md5    = md5("${password}${user}")
    # On bookworm we cant check the actual password, best we can do is ensure some SCRAM-SHA-256 password has been set
    $password_clause = debian::codename::ge('bookworm').bool2str("LIKE 'SCRAM-SHA-256\\\$4096:%'", "= 'md5${password_md5}'")
    $password_check = "/usr/bin/psql -Atc \"SELECT 1 FROM pg_authid WHERE rolname = '${user}' AND rolpassword ${password_clause};\" | grep 1"

    if $ensure == 'present' {
        exec { "create_user-${name}":
            command => "/usr/bin/createuser --no-superuser --no-createdb --no-createrole ${user}",
            user    => 'postgres',
            unless  => $userexists,
            require => Service[$postgresql::server::service_name],
        }

        # This will not be run on a slave as it is read-only
        if $master and $password {
            exec { "pass_set-${name}":
                command   => $pass_set,
                user      => 'postgres',
                unless    => $password_check,
                subscribe => Exec["create_user-${name}"],
                require   => Package["postgresql-${_pgversion}"],
            }
        }
    } elsif $ensure == 'absent' {
        exec { "drop_user-${name}":
            command => "/usr/bin/dropuser ${user}",
            user    => 'postgres',
            onlyif  => "${userexists} && ${user_dbs}",
            require => Package["postgresql-${_pgversion}"],
        }
    }

    # Host based access configuration for user connections
    $_cidrs.each |$_cidr| {
        postgresql::user::hba { "Access configuration for ${name} (${_cidr})":
            ensure    => $ensure,
            user      => $user,
            database  => $database,
            type      => $type,
            method    => $_method,
            cidr      => $_cidr,
            pgversion => $_pgversion,
        }
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
        postgresql::db_grant { "grant access to ${title} on ${database}":
            db            => $database,
            pg_role       => $user,
            table_priv    => $table_priv,
            sequence_priv => $sequence_priv,
            function_priv => $function_priv,
        }
    }
}
