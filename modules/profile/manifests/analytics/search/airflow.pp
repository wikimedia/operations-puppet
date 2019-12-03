# == Class profile::analytics::search::airflow
#
# Set up an apache-airflow instance to coordinate tasks
# in the analytics cluster.
#
class profile::analytics::search::airflow(
    Stdlib::Port $webserver_port  = lookup('profile::analytics::search::airflow::webserver_port'),
    Stdlib::Fqdn $mysql_host      = lookup('profile::analytics::search::airflow::mysql_host'),
    String $db_name               = lookup('profile::analytics::search::airflow::db_name'),
    String $deploy_target         = lookup('profile::analytics::search::airflow::deploy_target'),
    String $deploy_target_plugins = lookup('profile::analytics::search::airflow::deploy_target_plugins'),
    String $deploy_user           = lookup('profile::analytics::search::airflow::deploy_user'),
    Stdlib::Unixpath $deploy_dir  = lookup('profile::analytics::search::airflow::deploy_dir'),
    Stdlib::Unixpath $airflow_dir = lookup('profile::analytics::search::airflow::airflow_dir'),
    Stdlib::Unixpath $log_dir     = lookup('profile::analytics::search::airflow::log_dir'),
    Stdlib::Unixpath $pid_dir     = lookup('profile::analytics::search::airflow::pid_dir'),
    Stdlib::Unixpath $conf_dir    = lookup('profile::analytics::search::airflow::conf_dir'),
    String $conf_file             = lookup('profile::analytics::search::airflow::conf_file'),
) {
    include ::passwords::mysql::airflow::search

    require_package([
        'python3',
        'python3-virtualenv',
        'virtualenv',
        'python3-pip',
        'python3-mysqldb',
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


    # Deploy upstream airflow code + dependencies
    scap::target { $deploy_target:
        deploy_user => $deploy_user,
    }

    # Deploy dags + plugins
    scap::target { $deploy_target_plugins:
        deploy_user => $deploy_user,
    }

    file { $conf_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $sql_user = $::passwords::mysql::airflow::search::user
    $sql_pass = $::passwords::mysql::airflow::search::password
    $sql_alchemy_conn = "mysql://${sql_user}:${sql_pass}@${mysql_host}/${db_name}"

    file { "${conf_dir}/${conf_file}":
        ensure  => present,
        # Since this stores passwords limit read access
        owner   => 'root',
        group   => 'airflow',
        mode    => '0440',
        content => template('profile/analytics/search/airflow/airflow.cfg.erb'),
        require => Group['airflow'],
    }

    # Ensure places the daemons will write to are available.
    file { [$log_dir, $pid_dir]:
        ensure => 'directory',
        owner  => 'airflow',
        group  => 'airflow',
        mode   => '0755',
    }

    systemd::service { 'airflow-webserver':
        content => template('profile/analytics/search/airflow/webserver.service.erb'),
        require => File[$log_dir, $pid_dir, "${conf_dir}/${conf_file}"],
    }

    base::service_auto_restart { 'airflow-webserver': }

    systemd::service { 'airflow-scheduler':
        content => template('profile/analytics/search/airflow/scheduler.service.erb'),
        require => File[$log_dir, $pid_dir, "${conf_dir}/${conf_file}"],
    }

    base::service_auto_restart { 'airflow-scheduler': }
}
