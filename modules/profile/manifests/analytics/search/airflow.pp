# == Class profile::analytics::search::airflow
#
# Set up an apache-airflow instance to coordinate tasks
# in the analytics cluster.
#
class profile::analytics::search::airflow(
    $mysql_host = hiera('profile::analytics::search::airflow::mysql_host'),
    $webserver_port = hiera('profile::analytics::search::airflow::webserver_port', 8778),
    $db = hiera('profile::analytics::search::airflow::db', 'search_airflow')
) {
    include ::passwords::mysql::airflow::search

    require_package([
        'python3',
        'python3-virtualenv',
        'virtualenv',
        'python3-pip',
    ])

    group { 'airflow':
        ensure => present
    }

    user { 'airflow':
        ensure     => present,
        gid        => 'airflow',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
        require    => Group['airflow'],
    }

    $target = 'search/airflow'
    $deploydir = "/srv/deployment/${target}"
    $airflowdir = '/srv/deployment/wikimedia/search/analytics/airflow'
    $logdir = '/var/log/airflow'
    $piddir = '/var/run/airflow'

    # Deploy upstream airflow code + dependencies
    scap::target { $target:
        deploy_user => 'deploy-service',
    }

    # Deploy dags + plugins
    scap::target { 'wikimedia/discovery/analytics':
        deploy_user => 'deploy-service',
    }

    file { '/etc/airflow':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $sql_user = $::passwords::mysql::airflow::search::user # lint:ignore:wmf_styleguide
    $sql_pass = $::passwords::mysql::airflow::search::password # lint:ignore:wmf_styleguide
    $sql_alchemy_conn = "mysql://${sql_user}:${sql_pass}@${mysql_host}/${db}"

    file { '/etc/airflow/airflow.cfg':
        ensure  => present,
        # Since this stores passwords limit read access
        owner   => 'root',
        group   => 'airflow',
        mode    => '0440',
        content => template('profile/analytics/search/airflow/airflow.cfg.erb'),
        require => [
            File['/etc/airflow'],
            Group['airflow'],
        ]
    }

    # Ensure places the daemons will write are available
    file { [$logdir, $piddir]:
        ensure => 'dir',
        owner  => 'airflow',
        group  => 'airflow',
        mode   => '0755',
    }
}
