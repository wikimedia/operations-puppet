# == Define airflow::instance
#
# Sets up an instance of Apache Airflow.
# This uses the custom WMF airflow debian package.
# This package installs an isolated conda environment in
# /usr/lib/airflow.  Airflow instances run airflow
# from this conda environment with AIRFLOW_HOME defaulting
# to /srv/airflow-$title.  By default, all files (configs, dags, logs, etc.)
# belonging to the airflow instance live in /srv/airflow-$title.
#
# airflow.cfg is rendered directly from the $airflow_config Hash.
# A few smart airflow configs are set automatically:
#
# - core.sql_alchemy_conn
#   If this is set in $airflow_config, then it may be an ERB template string.
#   The final sql_alchemy_conn setting will render this template with local variable
#   context, which allows to include $db_user and $db_password in the sql_alchemy_conn string
#   without providing it directly in the $airflow_config param.  E.g.
#   mysql://:<%= @db_user %>:<%= @db_password %>@an-test-coord1001.eqiad.wmnet/airflow_analytics?ssl_ca=/etc/ssl/certs/Puppet_Internal_CA.pem
#
# - kerberos settings
#   If core.security == 'kerberos', it will be assumed that you are installing kerberos keytabs
#   using profile::kerberos::keytabs, and that the keytab for $service_user on this host is defined.
#   [kerberos] section configs will be set accordingly. You can still override these if you
#   need by setting any [kerberos] section configs in $airflow_config.
#
# === Parameters
# [*service_user*]
#   Airflow service user. airflow services and commands must be run as this user.
#
# [*service_group*]
#   Airflow service group.
#
# [*airflow_configs*]
#   Hash of airflow.cfg settings, keyed by section name.
#   E.g. { 'core' => { 'dags_folder' => '...' }, ... }
#
# [*airflow_home*]
#   Default: /srv/airflow-$title
#
# [*db_user*]
#   Only used for rendering a provided sql_alchemy_conn erb template string.
#   Default: airflow_$title
#
# [*db_password*]
#   Only used for rendering a provided sql_alchemy_conn erb template string.
#   Default: batman
#
# [*webserver_port*]
#   Default: 8600
#
# [*monitoring_enabled*]
#   Default: false
#
# [*clean_logs_older_than_days*]
#   If set, a systemd timer will be created to clean files from
#   airflow base_log_folder older than this many days.
#   If undef, the timer will not be created.
#   Default: 90
#
# [*ensure*]
#   Default: present
#
define airflow::instance(
    String $service_user,
    String $service_group,
    Hash $airflow_config                = {},
    Stdlib::Unixpath $airflow_home      = "/srv/airflow-${title}",
    String $db_user                     = "airflow_${title}",
    String $db_password                 = 'batman',
    Stdlib::Port $webserver_port        = 8600,
    Boolean $monitoring_enabled         = false,
    Integer $clean_logs_older_than_days = 90,
    Wmflib::Ensure $ensure              = 'present',
) {
    require ::airflow

    $airflow_prefix = $::airflow::airflow_prefix

    # First, construct smart default values and merge them together
    # to build $_airflow_config.  The $_airflow_config Hash will be usd
    # to render airflow.cfg.

    # Base airflow defaults.
    $airflow_config_defaults = {
        'core' => {
            'dags_folder' => "${airflow_home}/dags",
            'executor' => 'SequentialExecutor',
            'sql_alchemy_conn' => "sqlite:///${airflow_home}/airflow.db",
            'load_examples' => 'False',
            'load_default_connections' => 'False',
        },
        'logging' => {
            'base_log_folder' => "${airflow_home}/logs",
        }
    }

    # If $airflow_config specifies sql_alchemy_conn, we want to possibly render
    # it as an ERB template to apply $db_user and $db_password.
    if $airflow_config['core'] and $airflow_config['core']['sql_alchemy_conn'] {
        $airflow_config_sql_alchemy_conn = {
            'core' => {
                'sql_alchemy_conn' => inline_template($airflow_config['core']['sql_alchemy_conn'])
            }
        }
    } else {
        $airflow_config_sql_alchemy_conn = {}
    }

    # Default kerberos security settings if airflow security is set to kerberos.
    # Values from $airflow_config will take precedence over these.
    # These configs expect that a keytab for $service_user for this host has been
    # deployed via profile::kerberos::keytabs.
    if $airflow_config['core'] and $airflow_config['core']['security'] == 'kerberos' {
        $airflow_config_kerberos = {
            'kerberos' => {
                'ccache'           => "${airflow_home}/airflow_${service_user}_krb5_ccache",
                # gets augmented with fqdn
                'principal'        => "${service_user}/${::fqdn}@WIKIMEDIA",
                'reinit_frequency' => 3600,
                'kinit_path'       => 'kinit',
                'keytab'           => "/etc/security/keytabs/${service_user}/${service_user}.keytab",
            }
        }
    } else {
        $airflow_config_kerberos = {}
    }


    # Merge all the airflow configs we've got.  This is:
    # defaults <- kerberos <- provided config <- sql_alchemy_conn config with password
    $_airflow_config = deep_merge(
        $airflow_config_defaults,
        $airflow_config_kerberos,
        $airflow_config,
        $airflow_config_sql_alchemy_conn,
    )

    # Copied into local variables here for easy reference.
    $dags_folder = $_airflow_config['core']['dags_folder']
    $logs_folder = $_airflow_config['logging']['base_log_folder']
    $config_file = "${airflow_home}/airflow.cfg"


    # Default file resource params for this airflow instance.
    File {
        owner => $service_user,
        group => $service_group,
    }

    $ensure_directory = $ensure ? {
        absent  => $ensure,
        default => 'directory',
    }
    file { $airflow_home:
        ensure => $ensure_directory,
        mode   => '0755',
    }
    file { $config_file:
        ensure  => $ensure,
        mode    => '0440',
        content => template('airflow/airflow.cfg.erb'),
        require => File[$airflow_home],
    }

    # airflow command wrapper for this instance.
    # Aides running airflow commands without having to think about how
    # to properly set things like AIRFLOW_HOME.
    file { "/usr/local/bin/airflow-${title}":
        ensure  => $ensure,
        mode    => '0555',
        content => template('airflow/airflow.sh.erb'),
    }

    # Control service for all services for this airflow instance.
    systemd::service { "airflow@${title}":
        ensure               => $ensure,
        content              => systemd_template('airflow@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => File[$config_file],
    }

    # Airflow webserver for this instance.
    # TODO: add webserver_config.py with extra configs, e.g. LDAP?
    systemd::service { "airflow-webserver@${title}":
        ensure               => $ensure,
        content              => systemd_template('airflow-webserver@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => File[$config_file],
        service_params       => {
            'subscribe' => File[$config_file],
        }
    }
    base::service_auto_restart { "airflow-webserver@${title}":
        ensure => $ensure,
    }


    # Airflow scheduler for this instance.
    systemd::service { "airflow-scheduler@${title}":
        ensure               => $ensure,
        content              => systemd_template('airflow-scheduler@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => File[$config_file],
        service_params       => {
            'subscribe' => File[$config_file],
        },
    }
    base::service_auto_restart { "airflow-scheduler@${title}":
        ensure => $ensure,
    }


    # Only run airflow kerberos ticket renewer service if kerberos security is configured and
    # $ensure == 'present'
    if $_airflow_config['core']['security'] == 'kerberos' and $ensure == 'present' {
        $kerberos_ensure = 'present'
    } else {
        $kerberos_ensure = 'absent'
    }
    # Airflow kerberos for this instance.
    systemd::service { "airflow-kerberos@${title}":
        ensure               => $kerberos_ensure,
        content              => systemd_template('airflow-kerberos@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => File[$config_file],
        service_params       => {
            'subscribe' => File[$config_file],
        },
    }
    base::service_auto_restart { "airflow-kerberos@${title}":
        ensure => $kerberos_ensure,
    }


    # Set up monitoring services if $monitoring_enabled and $ensure == present
    if $monitoring_enabled and $ensure == 'present' {
        $monitoring_ensure = 'present'
    } else {
        $monitoring_ensure = 'absent'
    }
    $airflow_cmd = "/usr/bin/env AIRFLOW_HOME=${airflow_home} ${airflow_prefix}/bin/airflow"
    # See: https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/check-health.html
    nrpe::monitor_service { "airflow@${title}_check_scheduler":
        ensure       => $monitoring_ensure,
        nrpe_command => "/usr/local/bin/check_cmd ${airflow_cmd} jobs check --job-type SchedulerJob --hostname ${::fqdn}",
        description  => "Checks that the local airflow scheduler for airflow @${title} is working properly",
        # contact_group => 'victorops-analytics', TODO
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require      => Systemd::Service["airflow-scheduler@${title}"],
    }
    nrpe::monitor_service { "airflow@${title}_check_db":
        ensure       => $monitoring_ensure,
        nrpe_command => "/usr/local/bin/check_cmd ${airflow_cmd} db check",
        description  => "Checks that the airflow database for airflow ${title} is working properly",
        # contact_group => 'victorops-analytics', TODO
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require      => File[$config_file],
    }


    # Set up clean logs job if $clean_logs_older_than_days is set and $ensure == present
    if $clean_logs_older_than_days and $ensure == 'present' {
        $clean_logs_ensure = 'present'
    } else {
        $clean_logs_ensure = 'absent'
    }
    systemd::timer::job { "airflow_${title}_clean_logs":
        ensure      => $clean_logs_ensure,
        user        => 'root',
        description => "Delete airflow@${title} logs older than 90 days",
        command     => "/usr/bin/find ${logs_folder} -type f -mtime +${clean_logs_older_than_days} -delete && /usr/bin/find ${logs_folder} -type d -mtime +${clean_logs_older_than_days} -empty -delete",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 03:00:00',  # Every day at 3:00
        },
    }

}