# @summary Script to update PTR records for floating IPs
# @param ensure ensure the job is present/running or not
# @param project_zone_template template to use when generating zone names for projects
# @param reverse_zone_project project in which the in-addr.arpa. reverse zones live
class openstack::designate::dns_floating_ip_updater (
    Wmflib::Ensure $ensure,
    String[1]      $project_zone_template,
    String[1]      $reverse_zone_project,
) {
    $config = {
        'project_zone_template' => $project_zone_template,
        'reverse_zone_project'  => $reverse_zone_project,
        'retries'               => 2,
        'retry_interval'        => 120,
    }

    file { '/etc/wmcs-dns-floating-ip-updater.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => to_yaml($config),
    }

    file { '/usr/local/sbin/wmcs-dns-floating-ip-updater':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/openstack/designate/wmcs-dns-floating-ip-updater.py',
    }

    systemd::timer::job { 'designate_floating_ip_ptr_records_updater':
        ensure              => $ensure,
        description         => 'Designate Floating IP PTR records updater',
        command             => '/usr/local/sbin/wmcs-dns-floating-ip-updater',
        interval            => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00/15:00', # Every 15 minutes
        },
        max_runtime_seconds => 890,  # kill if running after 14m50s
        logging_enabled     => false,
        monitoring_enabled  => false,
        user                => 'root',
        require             => [
            File['/usr/local/sbin/wmcs-dns-floating-ip-updater'],
            File['/etc/wmcs-dns-floating-ip-updater.yaml'],
        ],
    }
}
