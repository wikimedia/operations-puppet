class profile::toolforge::harbor::db (
    String $harbor_pwd = lookup('profile::toolforge::harbor::db::harbor_pwd'),
    Optional[Stdlib::Host] $db_replica = lookup('profile::toolforge::harbor::db::replica', {default_value => undef}),
    Optional[String] $replication_pass = lookup('profile::toolforge::harbor::db::replication_pass', {default_value => undef}),
    Stdlib::Host $db_primary = lookup('profile::toolforge::harbor::db::primary'),
    Stdlib::Unixpath $root_dir = lookup('profile::toolforge::harbor::db::root_dir', {default_value => '/srv/postgres'}),
){
    require profile::wmcs::services::postgres::common
    require profile::prometheus::postgres_exporter

    if $db_primary == $facts['networking']['fqdn'] {
        # db_role is only used for the motd in role::wmcs::toolforce::harbor::db
        $db_role = 'primary'
        $on_primary = true
    } else {
        $db_role = 'replica'
        $on_primary = false
    }

    if $on_primary {
        class { 'postgresql::master':
            includes => ['tuning.conf'],
            root_dir => $root_dir,
        }
        if $db_replica {
            $db_replica_v4 = ipresolve($db_replica, 4)
            if $db_replica_v4 {
                postgresql::user { "replication@${db_replica}-v4":
                    ensure   => 'present',
                    user     => 'replication',
                    password => $replication_pass,
                    cidr     => "${db_replica_v4}/32",
                    type     => 'host',
                    method   => 'md5',
                    attrs    => 'REPLICATION',
                    database => 'all',
                }
            }
        }
        postgresql::user { 'harbor@eqiad1r':
            ensure   => 'present',
            user     => 'harbor',
            password => $harbor_pwd,
            cidr     => '172.16.0.0/21',
            type     => 'host',
            method   => 'trust',
            database => 'harbor',
        }
        postgresql::db { 'harbor':
            owner => 'harbor'
        }
    } elsif $replication_pass and $db_replica {
        class {'postgresql::slave':
            master_server    => $db_primary,
            replication_pass => $replication_pass,
            includes         => ['tuning.conf'],
            root_dir         => $root_dir,
        }
    } else {
        fail('If this is not the primary, this must have replication settings.')
    }
}
