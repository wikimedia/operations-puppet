# == Class profile::analytics::airflow
#
# Set up an apache-airflow instance to coordinate tasks
# in the analytics cluster.
#
class profile::analytics::airflow(
    String $service_user          = lookup('profile::analytics::airflow::service_user'),
    String $service_group         = lookup('profile::analytics::airflow::service_group'),
    Stdlib::Port $webserver_port  = lookup('profile::analytics::airflow::webserver_port'),
    Stdlib::Fqdn $mysql_host      = lookup('profile::analytics::airflow::mysql_host'),
    String $db_name               = lookup('profile::analytics::airflow::db_name'),
    String $deploy_target         = lookup('profile::analytics::airflow::deploy_target'),
    String $deploy_target_plugins = lookup('profile::analytics::airflow::deploy_target_plugins'),
    String $deploy_user           = lookup('profile::analytics::airflow::deploy_user'),
    Stdlib::Unixpath $deploy_dir  = lookup('profile::analytics::airflow::deploy_dir'),
    Stdlib::Unixpath $airflow_dir = lookup('profile::analytics::airflow::airflow_dir'),
    Stdlib::Unixpath $log_dir     = lookup('profile::analytics::airflow::log_dir'),
    Stdlib::Unixpath $run_dir     = lookup('profile::analytics::airflow::run_dir'),
    Stdlib::Unixpath $conf_dir    = lookup('profile::analytics::airflow::conf_dir'),
    String $conf_file             = lookup('profile::analytics::airflow::conf_file'),
    String $db_user               = lookup('profile::analytics::airflow::db_user'),
    String $db_password           = lookup('profile::analytics::airflow::db_password'),
) {
    ensure_packages([
        'python3',
        'python3-virtualenv',
        'virtualenv',
        'python3-pip',
        'python3-mysqldb',
    ])

    # wrapper script to run the airflow command in the right context
    $airflow_wrapper = '/usr/local/bin/airflow'
    file { $airflow_wrapper:
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('profile/analytics/airflow/airflow.sh.erb'),
    }

    # Deploy upstream airflow code + dependencies
    scap::target { $deploy_target:
        deploy_user => $deploy_user,
    }

    # Deploy dags + plugins
    scap::target { $deploy_target_plugins:
        deploy_user => $deploy_user,
    }

    if $deploy_user != $service_user {
        # Allow scap to deploy revision controlled variables
        sudo::user { "scap_${deploy_user}_${service_user}":
            user       => $deploy_user,
            privileges => ["ALL=(${service_user}) NOPASSWD: /usr/local/bin/airflow variables *" ]
        }
    }

    file { $conf_dir:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $sql_alchemy_conn = "mysql://${db_user}:${db_password}@${mysql_host}/${db_name}?ssl_ca=/etc/ssl/certs/wmf-ca-certificates.crt"

    file { "${conf_dir}/${conf_file}":
        ensure  => present,
        # Since this stores passwords limit read access
        owner   => 'root',
        group   => $service_group,
        mode    => '0440',
        content => template('profile/analytics/airflow/airflow.cfg.erb'),
        require => Group[$service_group],
    }

    # Ensure places the daemons will write to are available.
    file { [$log_dir, $run_dir]:
        ensure => 'directory',
        owner  => $service_user,
        group  => $service_group,
        mode   => '0755',
    }

    file { '/usr/local/bin/airflow-clean-log-dirs':
        content => template('profile/analytics/airflow/airflow-clean-log-dirs.erb'),
        mode    => '0550',
        owner   => 'root',
        group   => 'root',
    }

    systemd::timer::job { 'airflow_clean_log_dirs':
        user        => 'root',
        description => 'Delete Airflow log dirs/files after 30 days',
        command     => '/usr/local/bin/airflow-clean-log-dirs',
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 03:00:00',  # Every day at 3:00
        },
        require     => File['/usr/local/bin/airflow-clean-log-dirs'],
    }

    systemd::service { 'airflow-webserver':
        content => template('profile/analytics/airflow/webserver.service.erb'),
        require => File[$log_dir, $run_dir, "${conf_dir}/${conf_file}", $airflow_wrapper],
    }

    profile::auto_restarts::service { 'airflow-webserver': }

    systemd::service { 'airflow-scheduler':
        content => template('profile/analytics/airflow/scheduler.service.erb'),
        require => File[$log_dir, $run_dir, "${conf_dir}/${conf_file}", $airflow_wrapper],
    }

    profile::auto_restarts::service { 'airflow-scheduler': }

    systemd::service { 'airflow-kerberos':
        content => template('profile/analytics/airflow/kerberos.service.erb'),
        require => File[$log_dir, $run_dir, "${conf_dir}/${conf_file}", $airflow_wrapper],
    }

    profile::auto_restarts::service { 'airflow-kerberos': }

    # Include analytics mediawiki sql replica credentials at
    # /etc/mysql/conf.d/analytics-research-client.cnf. This is only readable to
    # users in analytics-privatedata-users group, $service_user must be externally
    # configured as a member of this group.
    statistics::mysql_credentials { $service_group:
        group => $service_group,
    }
}
