# SPDX-License-Identifier: Apache-2.0
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
# - core.sql_alchemy_conn (Deprecated on Airflow >= 2.3.0)
#   If this is set in $airflow_config, then it may be an ERB template string.
#   The final sql_alchemy_conn setting will render this template with local variable
#   context, which allows to include $db_user and $db_password in the sql_alchemy_conn string
#   without providing it directly in the $airflow_config param.  E.g.
#   mysql://:<%= @db_user %>:<%= @db_password %>@an-test-coord1001.eqiad.wmnet/airflow_analytics?ssl_ca=/etc/ssl/certs/wmf-ca-certificates.crt
#   Deprecated and replaced with database.sql_alchemy_conn defined below
#
# - database.sql_alchemy_conn
#   If this is set in $airflow_config, then it may be an ERB template string.
#   The final sql_alchemy_conn setting will render this template with local variable
#   context, which allows to include $db_user and $db_password in the sql_alchemy_conn string
#   without providing it directly in the $airflow_config param.  E.g.
#   postgresql://<%= @db_user %>:<%= @db_password %>@an-db1001.eqiad.wmnet:5432/airflow_data_engineering_dev?sslmode=require&sslrootcert=/etc/ssl/certs/wmf-ca-certificates.crt
#   connection also updated to a postgresql db on Airflow >= 2.3.0
#
# - kerberos settings
#   If core.security == 'kerberos', it will be assumed that you are installing kerberos keytabs
#   using profile::kerberos::keytabs, and that the keytab for $service_user on this host is defined.
#   [kerberos] section configs will be set accordingly. You can still override these if you
#   need by setting any [kerberos] section configs in $airflow_config.
#
# - smtp settings
#   These are set to defaults that will work in WMF production networks.
#
# - secrets backend
#   If $connections is provided, it will be rendered as $airflow_home/connections.yaml
#   and a secrets LocalFilesystemBackend will be configured to read connections out of this file.
#   See the $connections parameter for more info.
#   See also:
#   - https://airflow.apache.org/docs/apache-airflow/stable/security/secrets/secrets-backend/index.html
#   - https://airflow.apache.org/docs/apache-airflow/stable/security/secrets/secrets-backend/local-filesystem-secrets-backend.html
#
# NOTE: that airflow::instance will not create any databases or airflow users for you.
# To do this, see:
# https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html#setting-up-a-mysql-database
# https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html#setting-up-a-postgresql-database
#
# NOTE: This define does not yet support webserver_config.py customization. The webserver_config.py that
# is installed will grant Admin access to anyone that can access the webserver.  The default
# web_server_host is 127.0.0.1, so access is restricted to anyone who can ssh to the node
# running this airflow instance.  This may be improved in the future.
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
# [*connections*]
#   Optional hash of Airflow Connections as defined in
#   https://airflow.apache.org/docs/apache-airflow/stable/howto/connection.html.
#   If given, $airflow_home/connections.yaml will be rendered with these connections,
#   and a smart default Airflow [secrets] config for a Local Filesystem Secrets Backend
#   will be set to read connections out of this file. This allows for using Puppet
#   config management to manage Airflow connections, rather than having to define them
#   in the Airflow UI.
#   NOTE: These connections will not show up in the Airflow UI, but can be retrieved using
#   the airflow CLI like: airflow connections get <connection_name>.
#   They can of course be used in DAGs.
#
# [*environment_extra*]
#   Hash of environment variables to set in the airflow
#   instance's scheduler and webserver processes.
#   Default: {}
#
# [*monitoring_enabled*]
#   Enable monitoring of Airflow system services.
#   Default: false
#
# [*statsd_monitoring_enabled*]
#   Send Airflow metrics to statsd_exporter and then Prometheus.
#   Default: false
#
# [*clean_logs_older_than_days*]
#   If set, a systemd timer will be created to clean files from
#   airflow base_log_folder older than this many days.
#   If undef, the timer will not be created.
#   Default:
#
# [*firewall_srange*]
#   A firewall set used to configure firewall access using the generic firewall module.
#   Default: ANALYTICS_NETWORKS
#
# [*scheduler_srange*]
#   A string that resolves to a network range. This network range should be allowed
#   to reach the Airflow instances on their scheduler port ( which defaults to 8793/tcp ).
#   Default: DSE_KUBEPODS_NETWORKS

# [*scheduler_port* ]
#   An integer that represents the listening port for the Airflow instance's scheduler service.
#   Default: 8793

# [*scap_targets*]
#   scap::target resource definitions to declare.
#   This is useful to have here at the airflow::instance level so that we
#   can automate deployment of repositories needed for this airflow::instance.
#   These must also be declared in scap::sources in deployment_server.yaml hiera.
#   Default: undef
#
# [*ensure*]
#   Default: present
#
# [*renew_skein_certificate*]
#   If true, make sure the skein certificate is regularly regenerated
define airflow::instance(
    String $service_user,
    String $service_group,
    Hash $airflow_config                = {},
    Stdlib::Unixpath $airflow_home      = "/srv/airflow-${title}",
    String $db_user                     = "airflow_${title}",
    String $db_password                 = 'batman',
    Optional[String] $secret_key        = undef,
    Optional[Hash] $connections         = undef,
    Hash $environment_extra             = {},
    Boolean $monitoring_enabled         = false,
    Boolean $statsd_monitoring_enabled  = false,
    Integer $clean_logs_older_than_days = 90,
    String $firewall_srange             = 'ANALYTICS_NETWORKS',
    String $scheduler_srange            = 'DSE_KUBEPODS_NETWORKS',
    Integer $scheduler_port             = 8793,
    Optional[Hash] $scap_targets        = undef,
    Wmflib::Ensure $ensure              = 'present',
    Boolean $renew_skein_certificate    = true
) {
    # Require that something include the airflow base class
    # before using airflow::instance.
    Class['airflow'] -> Airflow::Instance[$title]

    $airflow_prefix = $::airflow::airflow_prefix

    # Declare any scap::targets for this instance.
    if $scap_targets != undef {
        create_resources('scap::target', $scap_targets)
    }

    # First, construct smart default values and merge them together
    # to build $_airflow_config.  The $_airflow_config Hash will be usd
    # to render airflow.cfg.

    # Base airflow defaults.
    $airflow_config_defaults = {
        'core' => {
            'dags_folder' => "${airflow_home}/dags",
            'executor' => 'SequentialExecutor',
            'load_examples' => 'False',
        },
        'logging' => {
            'base_log_folder' => "${airflow_home}/logs",
        },
        'webserver' => {
            'web_server_host'   => '0.0.0.0',
            'web_server_port'   => 8600,
            'instance_name'     => $title,
            # Since the webserver Public as Admin role, and is only accessible on 127.0.0.1 by default,
            # expose config for admins, except sensitives like passwords.
            'expose_config'     => 'non-sensitive-only',
            'expose_hostname'   => 'True',
            'expose_stacktrace' => 'True',
        },
        'scheduler' => {
            'parsing_processes' => $::processors['count'],
        },
        'smtp' => {
            # mail_smarthost is set globally in manifests/realm.pp
            'smtp_host' => $airflow::mail_smarthost[0],
            'smtp_starttls' => 'False',
            'smtp_ssl' => 'False',
            'smtp_port' => '25',
            'smtp_mail_from' => "Airflow: ${title} <noreply@wikimedia.org>",
        },
        'metrics' => {
            'statsd_on' => 'False',  # Turn this parameter on in hiera to enable statsd metrics.
            # statsd-exporter is running on the same machine
            'statsd_host' => 'localhost',
            'statsd_port' => '9125',
            'statsd_prefix' => 'airflow',
            # StatsD (https://github.com/etsy/statsd) integration settings.
            # If you want to avoid emitting all the available metrics, you can configure an
            # allow list of prefixes (comma separated) to send only the metrics that start
            # with the elements of the list (e.g: "scheduler,executor,dagrun")
            'metrics_allow_list' => 'operator_failures_,operator_successes_,sla_missed,executor.queued_tasks,dag.,dagrun.duration.,scheduler.scheduler_loop_duration,dag_processing.import_errors,dag_processing.total_parse_time,ti.failures,ti.successes,ti.finish,ti_failures,ti_successes',
            # If you want to utilise your own custom StatsD client set the relevant
            # module path below.
            # Note: The module path must exist on your PYTHONPATH for Airflow to pick it up
            'statsd_custom_client_path' => 'wmf_airflow_common.metrics.custom_statsd_client.CustomStatsClient'
        }
    }

    # Value to be used for sql_alchemy_conn if is not set in provided $airflow_config.
    $sql_alchemy_conn_default = "sqlite:///${airflow_home}/airflow.db"
    if $secret_key != '' and $secret_key != undef {
        $airflow_config_webserver_secret_key = {
            'webserver' => {
                'secret_key' => $secret_key,
            }
        }
    } else {
        $airflow_config_webserver_secret_key = {}
    }
    # This logic to be smart about core.sql_alchemy_conn can be removed
    # Once all airflow instances are upgraded.
    if $::airflow::version != undef and versioncmp($::airflow::version, '2.3.0') >= 0 {
        # If airflow version >= 2.3.0 use these new config defaults.
        $airflow_config_versioned = {
            'database' => {
                'load_default_connections' => 'False',
            },
            'api' => {
                # Since the webserver is only exposed on 127.0.0.1 by default,
                # allow access to the API.
                'auth_backends' => 'airflow.api.auth.backend.default',
            },
        }

        # If $airflow_config specifies sql_alchemy_conn, we want to possibly render
        # it as an ERB template to apply $db_user and $db_password.
        $sql_alchemy_conn = 'sql_alchemy_conn' in $airflow_config['database'] ? {
            true => inline_template($airflow_config['database']['sql_alchemy_conn']),
            false => $sql_alchemy_conn_default,
        }
        $airflow_config_sql_alchemy_conn = {
            # sql_alchemy_conn is in database section in airflow >= 2.3.0
            'database' => {
                'sql_alchemy_conn' => $sql_alchemy_conn
            }
        }
    } else {
        # Else use the airflow < 2.3.0 config defaults.
        $airflow_config_versioned = {
            'core' => {
                'load_default_connections' => 'False',
            },
            'api' => {
                # Since the webserver is only exposed on 127.0.0.1 by default,
                # allow access to the API.
                'auth_backend' => 'airflow.api.auth.backend.default',
            },
        }

        # If $airflow_config specifies sql_alchemy_conn, we want to possibly render
        # it as an ERB template to apply $db_user and $db_password.
        $sql_alchemy_conn = 'sql_alchemy_conn' in $airflow_config['core'] ? {
            true => inline_template($airflow_config['core']['sql_alchemy_conn']),
            false => $sql_alchemy_conn_default,
        }
        $airflow_config_sql_alchemy_conn = {
            # sql_alchemy_conn is in core section in airflow < 2.3.0
            'core' => {
                'sql_alchemy_conn' => $sql_alchemy_conn
            }
        }
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


    # If we are given $connections, we should render them into a connections.yaml file
    # that will be used by the Airflow LocalFilesystemBackend.  This allows us to manage
    # Airflow connections using Puppet, rather than in the Web UI and stored in the Airflow
    # database.
    $connections_file = "${airflow_home}/connections.yaml"
    if $connections {
        $airflow_config_secrets = {
            'secrets' => {
                'backend' => 'airflow.secrets.local_filesystem.LocalFilesystemBackend',
                'backend_kwargs' => "{\"connections_file_path\": \"${connections_file}\"}",
            }
        }
    } else {
        $airflow_config_secrets = {}
    }

    # Merge all the airflow configs we've got.  This is:
    # defaults <- kerberos <- secrets config <- provided config <- airflow_config_new_syntax config with password
    $_airflow_config = deep_merge(
        $airflow_config_defaults,
        $airflow_config_kerberos,
        $airflow_config_secrets,
        $airflow_config_versioned,
        $airflow_config_webserver_secret_key,
        $airflow_config,
        # Usually, we'd put $airflow_config last,
        # so it would take precedence over all default configs.
        # sql_alchemy_conn is a special case, because we've already
        # considered the $airflow_config provided setting in the above code.
        # We've rendered the provided sql_alchemy_conn value as a template
        # into $airflow_config_sql_alchemy_conn.
        $airflow_config_sql_alchemy_conn,
    )

    # Copied into local variables here for easy reference.
    $dags_folder = $_airflow_config['core']['dags_folder']
    $logs_folder = $_airflow_config['logging']['base_log_folder']
    $airflow_config_file = "${airflow_home}/airflow.cfg"
    $webserver_config_file = "${airflow_home}/webserver_config.py"
    $webserver_port = $_airflow_config['webserver']['web_server_port']
    $profile_file = "${airflow_home}/bin/airflow-${title}-profile.sh"
    $airflow_cli_file = "${airflow_home}/bin/airflow-${title}"


    # Default file resource params for this airflow instance.
    File {
        owner => $service_user,
        group => $service_group,
    }

    $ensure_directory = $ensure ? {
        absent  => $ensure,
        default => 'directory',
    }
    $ensure_link = $ensure ? {
        absent => $ensure,
        default => 'link',
    }

    file { [$airflow_home, "${airflow_home}/bin"]:
        ensure => $ensure_directory,
        force  => true,
        mode   => '0755',
    }
    file { $airflow_config_file:
        ensure  => $ensure,
        mode    => '0440', # Likely has $db_password in it.
        content => template('airflow/airflow.cfg.erb'),
        require => File[$airflow_home],
    }

    file { $profile_file:
        ensure  => $ensure,
        mode    => '0444',
        content => template('airflow/profile.sh.erb')
    }

    # airflow CLI wrapper for this instance.
    # Aides running airflow commands without having to think about how
    # to properly set things like AIRFLOW_HOME.
    file { $airflow_cli_file:
        ensure  => $ensure,
        mode    => '0555',
        content => template('airflow/airflow.sh.erb'),
        require => File[$profile_file],
    }
    # Link the airflow command wrapper in /usr/local/bin
    # so it is on regular users PATH.
    file { "/usr/local/bin/airflow-${title}":
        ensure  => $ensure_link,
        target  => "${airflow_home}/bin/airflow-${title}",
        require => File[$airflow_cli_file],
    }

    # No per instance webserver configuration yet.
    # For now, any access to webserver UI port grants Admin access.
    file { $webserver_config_file:
        ensure => $ensure,
        mode   => '0444',
        source => 'puppet:///modules/airflow/webserver_config.py'
    }

    if $dags_folder == "${airflow_home}/dags" {
        # Create $dags_folder if in $airflow_home
        file { $dags_folder:
            ensure => $ensure_directory,
            force  => true,
            mode   => '0755',
        }
    } else {
        # Else create $airflow_home/dags as a symlink
        file { "${airflow_home}/dags":
            ensure => $ensure_link,
            target => $dags_folder,
        }
    }

    # If $connections have been defined, render the connections.yaml file.
    if $connections and $ensure == 'present' {
        $connections_file_ensure = 'present'
    } else {
        $connections_file_ensure = 'absent'
    }
    file { $connections_file:
        ensure  => $connections_file_ensure,
        mode    => '0440', # Could have secrets in it.
        content => template('airflow/connections.yaml.erb')
    }

    # DRY variable for dependencies for airflow webserver and scheduler services.
    $service_dependencies = [
        File[$airflow_config_file],
        File[$webserver_config_file],
        File[$connections_file],
        File[$profile_file],
    ]

    # Control service for all services for this airflow instance.
    systemd::service { "airflow@${title}":
        ensure               => $ensure,
        content              => systemd_template('airflow@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => $service_dependencies,
    }

    # Airflow webserver for this instance.
    systemd::service { "airflow-webserver@${title}":
        ensure               => $ensure,
        content              => systemd_template('airflow-webserver@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => $service_dependencies,
        service_params       => {
            'subscribe' => $service_dependencies,
        }
    }
    profile::auto_restarts::service { "airflow-webserver@${title}":
        ensure => $ensure,
    }


    # Airflow scheduler for this instance.
    systemd::service { "airflow-scheduler@${title}":
        ensure               => $ensure,
        content              => systemd_template('airflow-scheduler@'),
        restart              => true,
        monitoring_enabled   => $monitoring_enabled,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require              => $service_dependencies,
        service_params       => {
            'subscribe' => $service_dependencies,
        },
    }
    profile::auto_restarts::service { "airflow-scheduler@${title}":
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
        require              => File[$airflow_config_file],
        service_params       => {
            'subscribe' => File[$airflow_config_file],
        },
    }
    profile::auto_restarts::service { "airflow-kerberos@${title}":
        ensure => $kerberos_ensure,
    }


    # Set up monitoring services if $monitoring_enabled and $ensure == present
    if $monitoring_enabled and $ensure == 'present' {
        $monitoring_ensure = 'present'
    } else {
        $monitoring_ensure = 'absent'
    }
    $airflow_cmd = "/usr/bin/env PYTHONPATH=/srv/deployment/airflow-dags/${title} AIRFLOW_HOME=${airflow_home} ${airflow_prefix}/bin/airflow"
    # See: https://airflow.apache.org/docs/apache-airflow/stable/logging-monitoring/check-health.html

    $check_scheduler_command = "/usr/local/bin/check_cmd ${airflow_cmd} jobs check --job-type SchedulerJob --hostname ${::fqdn}"
    $check_db_command = "/usr/local/bin/check_cmd ${airflow_cmd} db check"

    sudo::user { "airflow_checks_${title}":
        ensure => absent,
    }

    nrpe::monitor_service { "airflow@${title}_check_scheduler":
        ensure       => $monitoring_ensure,
        nrpe_command => $check_scheduler_command,
        sudo_user    => $service_user,
        description  => "Checks that the local airflow scheduler for airflow @${title} is working properly",
        # contact_group => 'victorops-analytics', TODO
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require      => Systemd::Service["airflow-scheduler@${title}"],
    }
    nrpe::monitor_service { "airflow@${title}_check_db":
        ensure       => $monitoring_ensure,
        nrpe_command => $check_db_command,
        sudo_user    => $service_user,
        description  => "Checks that the airflow database for airflow ${title} is working properly",
        # contact_group => 'victorops-analytics', TODO
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Airflow',
        require      => File[$airflow_config_file],
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
        command     => "/usr/local/bin/clean_logs ${logs_folder} ${clean_logs_older_than_days}",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* 03:00:00',  # Every day at 3:00
        },
    }

    firewall::service { "airflow-webserver@${title}":
        proto    => 'tcp',
        port     => $webserver_port,
        src_sets => [$firewall_srange],
    }

    firewall::service { 'scheduler-port':
        proto    => 'tcp',
        port     => $scheduler_port,
        src_sets => [$scheduler_srange],
    }

    $skein_cert_path = "${airflow_home}/.skein/skein.crt"
    prometheus::node_textfile { 'prometheus-check-certificate-expiry':
        ensure         => 'present',
        filesource     => 'puppet:///modules/prometheus/check_certificate_expiry.py',
        interval       => 'daily',
        run_cmd        => "/usr/local/bin/prometheus-check-certificate-expiry --cert-path ${skein_cert_path} --outfile /var/lib/prometheus/node.d/x509-skein.prom",
        extra_packages => ['python3-cryptography', 'python3-prometheus-client'],
    }

    if $renew_skein_certificate {
        systemd::timer::job { 'regenerate-skein-certificate':
            ensure      => 'present',
            description => 'refresh the x509 self-signed Skein certificate',
            user        => $service_user,
            environment => {'HOME' => $airflow_home},
            command     => '/lib/airflow/bin/skein config gencerts --force',
            interval    => [
                {
                    'start'    => 'OnCalendar',
                    # at 10AM UTC on each Tuesday. See https://phabricator.wikimedia.org/T350945 for rationale
                    'interval' => 'Tue 10:00',
                }
            ]
        }
    }

}
