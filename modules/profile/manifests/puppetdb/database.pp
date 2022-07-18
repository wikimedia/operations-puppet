# @summary Sets up a puppetdb postgresql database.
#
# @param master The primary db server
# @param shared_buffers The amount of mem to use for shared buffers
# @param replication_password password used for replication
# @param users A hash of useres to create
# @param replication_lag_crit when the icinga alert should go critical
# @param replication_lag_warn when the icinga alert should start warning
# @param log_line_prefix Log line formatting prefix
# @param use_replication_slots if true configure postgres to use replication slots
# @param slaves A list of slave servers
# @param ssldir The ssl directory
# @param log_min_duration_statement Log transaction that take longer then this value in milliseconds
# @param log_autovacuum_min_duration Log autovacum if it take longer then this time in milliseconds
class profile::puppetdb::database(
    Stdlib::Host               $master                  = lookup('profile::puppetdb::master'),
    Stdlib::Datasize           $shared_buffers          = lookup('profile::puppetdb::database::shared_buffers'),
    String                     $replication_password    = lookup('puppetdb::password::replication'),
    Hash                       $users                   = lookup('profile::puppetdb::database::users'),
    Integer                    $replication_lag_crit    = lookup('profile::puppetdb::database::replication_lag_crit'),
    Integer                    $replication_lag_warn    = lookup('profile::puppetdb::database::replication_lag_warn'),
    String                     $log_line_prefix         = lookup('profile::puppetdb::database::log_line_prefix'),
    Boolean                    $use_replication_slots   = lookup('profile::puppetdb::database::use_replication_slots'),
    Array[Stdlib::Host]        $slaves                  = lookup('profile::puppetdb::slaves'),
    Optional[Stdlib::Unixpath] $ssldir                  = lookup('profile::puppetdb::database::ssldir'),
    Optional[Integer[250]] $log_min_duration_statement  = lookup('profile::puppetdb::database::log_min_duration_statement'),
    Optional[Integer]      $log_autovacuum_min_duration = lookup('profile::puppetdb::database::log_autovacuum_min_duration'),
) {
    $pgversion = debian::codename() ? {
        'bullseye' => 13,
        'buster'   => 11,
    }
    $slave_range = join($slaves, ' ')
    if $master == $facts['networking']['fqdn'] {
        # db_role is only used for the motd in role::puppetdb
        $db_role = 'primary'
        $on_master = true
    } else {
        $db_role = 'replica'
        $on_master = false
    }

    sysctl::parameters { 'postgres_shmem':
        values => {
            # That is derived after tuning postgresql, deriving automatically is
            # not the safest idea yet.
            'kernel.shmmax' => 8388608000,
        },
    }
    if $on_master {
        $replication_slots = $use_replication_slots ? {
            true    => $slaves.map |$replica| { "puppet_${replica.regsubst('\.', '_', 'G')}"  },
            default => [],
        }
        class { 'postgresql::master':
            includes                    => ['tuning.conf'],
            root_dir                    => '/srv/postgres',
            use_ssl                     => true,
            ssldir                      => $ssldir,
            log_line_prefix             => $log_line_prefix,
            log_min_duration_statement  => $log_min_duration_statement,
            log_autovacuum_min_duration => $log_autovacuum_min_duration,
            replication_slots           => $replication_slots,
        }
    } else {
        $replication_slot_name = $use_replication_slots ? {
            true    => "puppetdb_${facts['networking']['fqdn'].regsubst('\.', '_', 'G')}",
            default => undef,
        }
        class { 'postgresql::slave':
            includes              => ['tuning.conf'],
            master_server         => $master,
            root_dir              => '/srv/postgres',
            replication_pass      => $replication_password,
            use_ssl               => true,
            replication_slot_name => $replication_slot_name,
        }
        class { 'postgresql::slave::monitoring':
            pg_master   => $master,
            pg_user     => 'replication',
            pg_password => $replication_password,
            pg_database => 'puppetdb',
            critical    => $replication_lag_crit,
            warning     => $replication_lag_warn,
        }
    }
    file { "/etc/postgresql/${pgversion}/main/tuning.conf":
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('puppetmaster/puppetdb/tuning.conf.erb'),
        require => Package["postgresql-${pgversion}"],
    }
    $users.each |$pg_name, $config| {
        postgresql::user { $pg_name:
            * => $config + {'master' => $on_master, 'pgversion' => $pgversion},
        }
    }
    postgresql::db { 'puppetdb':
        owner   => 'puppetdb',
    }
    # Ensure dbs created before grants
    Postgresql::Db<| |> -> Postgresql::Db_grant<| |>

    exec { 'create_tgrm_extension':
        command => '/usr/bin/psql puppetdb -c "create extension pg_trgm"',
        unless  => '/usr/bin/psql puppetdb -c \'\dx\' | /bin/grep -q pg_trgm',
        user    => 'postgres',
        require => Postgresql::Db['puppetdb'],
    }
    # Firewall rules
    # Allow connections from all the slaves
    ferm::service { 'postgresql_puppetdb':
        proto  => 'tcp',
        port   => 5432,
        srange => "@resolve((${slave_range}))",
    }
}
