# === Class wdqs::updater
#
# Wikidata Query Service updater service.
#
class wdqs::updater(
    $logstash_host,
    $logstash_json_tcp_port = 11514,
    $options = '-n wdq -s',
    $package_dir = $::wdqs::package_dir,
    $username = $::wdqs::username,
){

    file { '/etc/default/wdqs-updater':
        ensure  => present,
        content => template('wdqs/updater-default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        before  => Base::Service_unit['wdqs-updater'],
    }

    base::service_unit { 'wdqs-updater':
        template_name  => 'wdqs-updater',
        systemd        => systemd_template('wdqs-updater'),
        upstart        => upstart_template('wdqs-updater'),
        service_params => {
            enable => true,
        },
        require        => [ File['/etc/wdqs/updater-logs.xml'],
                            Service['wdqs-blazegraph'] ],
    }
}
