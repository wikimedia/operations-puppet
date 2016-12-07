# == Class clickhouse
#
# Yandex Clickhouse (https://clickhouse.yandex)
# More info: https://clickhouse.yandex/reference_en.html#What is ClickHouse?
#
# == Parameters
#
# [*clusters*]
#   Clusters to be defined in ClickHouse. Each list of replicas corresponds
#   to a shard configured for its related cluster.
#
#   Ref: https://clickhouse.yandex/reference_en.html#Distributed
#   Example:
#   {
#     "cluster1" => [['replica1.hostname', replica1.hostname'],
#                    ['replica3.hostname', replica4.hostname']], 
#     "cluster2" => [['replica3.hostname', replica4.hostname']],
#     ...
#    }
#   In the above example two clusters are defined: the first one contains
#   two shards, meanwhile the second only one. All the shards defined contains
#   two replicas.
#

class clickhouse (
    $clusters                = {},
    $zookeeper_hosts         = ['localhost'],
    $zookeeper_port          = 2181,
    $interserver_http_port   = 9009,
    $tcp_port                = 9000,
    $http_server_port        = 8123,
    $http_server_accept_from = '::',
    $http_server_max_conns   = 4096,
    $http_server_ka_timeout  = 3,
    $max_concurrent_queries  = 100,
    $max_memory_usage        = 10000000000,
    $uncompressed_cache_size = 8589934592,
    $mark_cache_size         = 5368709120,
    $builtin_dict_reload_int = 3600,
    $data_dir                = '/srv/clickhouse',
    $tmp_processing_dir      = '/tmp/',
    $log_dir                 = '/var/log/clickhouse',
    $log_level               = 'info',
    $log_rotation_max_size   = '100M',
    $log_rotation_max_files  = 10,
    $graphite_host           = undef,
    $graphite_port           = undef,
    $graphite_metric_prefix  = 'clickhouse',
    $graphite_timeout        = 0.1,
    $contact_group           = 'admins'
)
{

    requires_os('debian >= jessie')
    require_package('clickhouse')

    group { 'clickhouse':
        ensure => present,
        system => true,
    }

    user { 'clickhouse':
        gid     => 'clickhouse',
        shell   => '/bin/bash',
        system  => true,
        require => Group['clickhouse'],
    }

    file { '/etc/clickhouse':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/clickhouse/users.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('clickhouse/users.xml.erb'),
        require => File['/etc/clickhouse'],
    }

    file { '/etc/clickhouse/config.xml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('clickhouse/config.xml.erb'),
        require => File['/etc/clickhouse','/etc/clickhouse/users.xml']
    }

    systemd::syslog { 'clickhouse':
        readable_by => 'all',
        base_dir    => '/var/log',
        group       => 'root',
    }

    base::service_unit { 'clickhouse':
        ensure  => present,
        systemd => true,
        require => [
            File['/etc/clickhouse/config.xml'],
            User['clickhouse'],
            Systemd::Syslog['clickhouse'],
        ],
    }

    monitoring::service { 'clickhouse':
        description   => 'clickhouse',
        check_command => "check_tcp!${tcp_port}",
        contact_group => $contact_group,
        require       => Base::Service_unit['clickhouse'],
    }
}
