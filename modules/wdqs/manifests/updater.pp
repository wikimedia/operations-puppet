# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
# Note: Installs and start the wdqs-updater service.
# == Parameters:
# - $options: extra updater options, passed to runUpdate.sh script.
# - $package_dir:  Directory where the service should be installed.
# - $data_dir: Directory where the database should be stored.
# - $log_dir: Directory where the logs go.
# - $logstash_logback_port: port which rsyslog server is listening on
# - $username: Username owning the service.
# - $extra_jvm_opts: extra JVM options for updater.
# - $log_sparql: enable SPARQL logging.
class wdqs::updater(
    Array[String] $options,
    Stdlib::Unixpath $package_dir,
    Stdlib::Unixpath $data_dir,
    Stdlib::Unixpath $log_dir,
    Stdlib::Port $logstash_logback_port,
    String $username,
    Array[String] $extra_jvm_opts,
    Boolean $log_sparql = false,
) {
    file { '/etc/default/wdqs-updater':
        ensure  => present,
        content => template('wdqs/updater-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Systemd::Unit['wdqs-updater'],
        notify  => Service['wdqs-updater'],
    }

    wdqs::logback_config { 'wdqs-updater':
        pattern               => '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg %mdc%n',
        log_dir               => $log_dir,
        logstash_logback_port => $logstash_logback_port,
        sparql                => $log_sparql,
    }

    systemd::unit { 'wdqs-updater':
        content => template('wdqs/initscripts/wdqs-updater.systemd.erb'),
        notify  => Service['wdqs-updater'],
    }

    service { 'wdqs-updater':
        ensure => 'running',
    }
}
