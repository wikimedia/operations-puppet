# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
# Note: this class references the main wdqs class. It is the responsibility of
# the caller to make sure that the main wdqs calss is instantiated or that the
# parameter $package_dir and $username are set on the wdqs::updater class.
#
class wdqs::updater(
    $options,
    $logstash_host,
    $logstash_json_port = 11514,
    $package_dir = $::wdqs::package_dir,
    $username = $::wdqs::username,
    $data_dir = $::wdqs::data_dir,
    $extra_jvm_opts = undef,
){
    file { '/etc/default/wdqs-updater':
        ensure  => present,
        content => template('wdqs/updater-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Systemd::Unit['wdqs-updater'],
    }

    wdqs::logback_config { 'wdqs-updater':
        pattern       => '%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n',
        logstash_host => $logstash_host,
        logstash_port => $logstash_json_port,
    }

    systemd::unit { 'wdqs-updater':
        content => template('wdqs/initscripts/wdqs-updater.systemd.erb'),
    }
    service { 'wdqs-updater':
        ensure => 'running',
    }
}
