# == Class profile::puppetdb::database
#
# Sets up a puppetdb postgresql database.
#
class profile::puppetdb::database(
    Stdlib::Host $master         = lookup('profile::puppetdb::master'),
    String $shared_buffers       = lookup('profile::puppetdb::database::shared_buffers'),
    String $replication_password = lookup('puppetdb::password::replication'),
    String $puppetdb_password    = lookup('puppetdb::password::rw'),
    Hash   $users                = lookup('profile::puppetdb::database::users'),
    Integer$replication_lag_crit = lookup('profile::puppetdb::database::replication_lag_crit'),
    Integer$replication_lag_warn = lookup('profile::puppetdb::database::replication_lag_warn'),
    Optional[Array[Stdlib::Host]] $slaves = lookup('profile::puppetdb::slaves'),
    Optional[Stdlib::Unixpath]    $ssldir = lookup('profile::puppetdb::database::ssldir',
                                                  {'default_value' => undef}),
) {
    $pgversion = $facts['os']['distro']['codename'] ? {
        'buster'  => 11,
        'stretch' => 9.6,
    }
    $slave_range = join($slaves, ' ')

    $role = $master ? {
        $::fqdn => 'master',
        default => 'slave',
    }

    class { '::puppetmaster::puppetdb::database':
        master           => $master,
        pgversion        => $pgversion,
        shared_buffers   => $shared_buffers,
        replication_pass => $replication_password,
        puppetdb_pass    => $puppetdb_password,
        puppetdb_users   => $users,
        ssldir           => $ssldir,
    }

    if $role == 'slave' {
        class { 'postgresql::slave::monitoring':
            pg_master   => $master,
            pg_user     => 'replication',
            pg_password => $replication_password,
            pg_database => 'puppetdb',
            critical    => $replication_lag_crit,
            warning     => $replication_lag_warn,
        }
    }

    # Firewall rules
    # Allow connections from all the slaves
    ferm::service { 'postgresql_puppetdb':
        proto  => 'tcp',
        port   => 5432,
        srange => "@resolve((${slave_range}))",
    }
}
