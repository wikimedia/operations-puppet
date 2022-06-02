# SPDX-License-Identifier: Apache-2.0
# === Class query_service::updater
#
# Query Service updater service.
#
# Note: Installs and start the query service updater service.
# == Parameters:
# - $options: extra updater options, passed to runUpdate.sh script.
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored.
# - $log_dir: Directory where the logs go.
# - $logstash_logback_port: port which rsyslog server is listening on
# - $username: Username owning the service.
# - $deploy_name: Name of the deployment (e.g. wdqs or wcqs)
# - $extra_jvm_opts: extra JVM options for updater.
# - $journal: Name to assign instance journal. Must be unique per data_dir (used by updater.systemd.erb).
# - $log_sparql: enable SPARQL logging.
class query_service::updater(
    Array[String] $options,
    Stdlib::Unixpath $package_dir,
    Stdlib::Unixpath $data_dir,
    Stdlib::Unixpath $log_dir,
    Stdlib::Port $logstash_logback_port,
    String $username,
    String $deploy_name,
    Array[String] $extra_jvm_opts,
    String $journal,
    Boolean $log_sparql = false,
) {
    $updater_startup_script = 'runStreamingUpdater.sh'
    $updater_service_desc = 'Query Service Streaming Updater'

    file { '/etc/default/query-service-updater':
        ensure  => present,
        content => template('query_service/updater-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Systemd::Unit["${deploy_name}-updater"],
        notify  => Service["${deploy_name}-updater"],
    }

    query_service::logback_config { "${deploy_name}-updater":
        pattern               => '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg %mdc%n',
        log_dir               => $log_dir,
        logstash_logback_port => $logstash_logback_port,
        deploy_name           => $deploy_name,
        sparql                => $log_sparql,
    }

    systemd::unit { "${deploy_name}-updater":
        content => template('query_service/initscripts/updater.systemd.erb'),
        notify  => Service["${deploy_name}-updater"],
    }

    service { "${deploy_name}-updater":
        ensure => 'running',
    }
}
