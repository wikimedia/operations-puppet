# == Class profile::puppetdb::database
#
# Sets up a puppetdb postgresql database.
#
class profile::puppetdb::database(
    $master = hiera('profile::puppetdb::master'),
    $slaves = hiera('profile::puppetdb::slaves', []),
    $shared_buffers = hiera('profile::puppetdb::database::shared_buffers', '7680MB'),
    $replication_password = hiera('puppetdb::password::replication'),
    $puppetdb_password =  hiera('puppetdb::password::rw'),
    $users = hiera('profile::puppetdb::database::users', {}),
    $ssldir = hiera('profile::puppetdb::database::ssldir', undef),
) {
    include ::passwords::postgres

    $pgversion = $::lsbdistcodename ? {
        'stretch' => '9.6',
        'jessie'  => '9.4',
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
