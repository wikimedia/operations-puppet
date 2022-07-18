# Class: postgresql::master
#
# This class installs the server in a master configuration
#
# Parameters:
# @param ensure
#       Defaults to present
# @param master_server
#       An FQDN. Defaults to $::fqdn. Should be the same as in slaves configured with this module
# @param max_wal_senders
#       Defaults to 5. Refer to postgresql documentation for its meaning
# @param wal_keep_segments
#       Defaults to 128. Refer to postgresql documentation for its meaning
# @param root_dir
#       See $postgresql::server::root_dir
# @param use_ssl
#       Enable ssl
# @param locale
#       Locale used to initialise posgresql cluster.
#       Setting the locale ensure that locale and encodings will be the same
#       whether $LANG and $LC_* are set or not.
# @param sync_count
#       number of synchronous standbys that transactions need to wait for replies from
# @param sync_mode
#       synchronous replication mode
# @param log_line_prefix
#       The prefix to use for log messages
# @param includes
#       An array of files to be included by the main configuration
# @param ssldir
#       location of the ssl directory
# @param sync_replicas
#       a list of standby servers to configure with synchronous replication
# @param log_min_duration_statement
#   `   log queries that take longer then this in milliseconds
# @param log_autovacuum_min_duration
#   `   log autovacuum that take longer then this in milliseconds
# @param checkpoint_segments
#       Defaults to 64. Refer to postgresql documentation for its meaning
# @param pgversion
#       Defaults to 9.6 in Debian Stretch and 11 in Buster
#
# @example
#  include postgresql::master

class postgresql::master(
    Wmflib::Ensure             $ensure                      = 'present',
    Stdlib::Host               $master_server               = $facts['networking']['fqdn'],
    Integer                    $max_wal_senders             = 5,
    Integer                    $checkpoint_segments         = 64,
    Integer                    $wal_keep_segments           = 128,
    Stdlib::Unixpath           $root_dir                    = '/var/lib/postgresql',
    Boolean                    $use_ssl                     = false,
    String                     $locale                      = 'en_US.UTF-8',
    Integer                    $sync_count                  = 1,
    String                     $sync_mode                   = 'on',
    String                     $log_line_prefix             = '%t ',
    Array[String]              $includes                    = [],
    Optional[Stdlib::Unixpath] $ssldir                      = undef,
    Optional[Array[String]]    $sync_replicas               = undef,
    Optional[Integer[250]]     $log_min_duration_statement  = undef,
    Optional[Integer]          $log_autovacuum_min_duration = undef,
    Optional[Numeric]          $pgversion                   = undef,
) {

    $_pgversion = $pgversion ? {
        undef   => debian::codename() ? {
            'stretch'  => 9.6,
            'buster'   => 11,
            'bullseye' => 13,
            default    => fail("${title} not supported by: ${debian::codename()})")
        },
        default => $pgversion,
    }
    $data_dir = "${root_dir}/${_pgversion}/main"

    class { 'postgresql::server':
        ensure                      => $ensure,
        pgversion                   => $_pgversion,
        includes                    => $includes + ['master.conf'],
        root_dir                    => $root_dir,
        use_ssl                     => $use_ssl,
        ssldir                      => $ssldir,
        log_line_prefix             => $log_line_prefix,
        log_min_duration_statement  => $log_min_duration_statement,
        log_autovacuum_min_duration => $log_autovacuum_min_duration,
    }

    file { "/etc/postgresql/${_pgversion}/main/master.conf":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('postgresql/master.conf.erb'),
        require => Class['postgresql::server'],
    }

    if $ensure == 'present' {
        exec { 'pg-initdb':
            command => "/usr/lib/postgresql/${_pgversion}/bin/initdb --locale ${locale} -D ${data_dir}",
            user    => 'postgres',
            unless  => "/usr/bin/test -f ${data_dir}/PG_VERSION",
            require => Class['postgresql::server'],
        }
    }
}
