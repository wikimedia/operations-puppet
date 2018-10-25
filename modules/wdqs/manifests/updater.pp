# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
# Note: this class references the main wdqs class. It is the responsibility of
# the caller to make sure that the main wdqs class is instantiated or that the
# parameter $package_dir and $username are set on the wdqs::updater class.
#
class wdqs::updater(
    String $options,
    String $logstash_host,
    Wmflib::IpPort $logstash_json_port = 11514,
    Stdlib::Unixpath $log_dir = $::wdqs::log_dir,
    Stdlib::Unixpath $package_dir = $::wdqs::package_dir,
    String $username = $::wdqs::username,
    Stdlib::Unixpath $data_dir = $::wdqs::data_dir,
    Array[String] $extra_jvm_opts = [],
){
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
        pattern       => '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n',
        log_dir       => $log_dir,
        logstash_host => $logstash_host,
        logstash_port => $logstash_json_port,
    }

    systemd::unit { 'wdqs-updater':
        content => template('wdqs/initscripts/wdqs-updater.systemd.erb'),
        notify  => Service['wdqs-updater'],
    }
    service { 'wdqs-updater':
        ensure => 'running',
    }

    sudo::user { 'deploy-service_wdqs-updater':
        user       => 'deploy-service',
        privileges => [
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater start',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater stop',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater reload',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater status',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater try-restart',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater force-reload',
            'ALL=(root) NOPASSWD: /usr/sbin/service wdqs-updater graceful-stop'
        ],
    }
}
