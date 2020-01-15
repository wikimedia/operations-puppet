# == openstack::designate::dns_floating_ip_updater ==
#
# === Parameters ===
# [*floating_ip_pr_zone*]
#    Reverse DNS zone
# [*floating_ip_ptr_fqdn_matching_regex*]
#    Regular expression that matches PTR records
# [*floating_ip_ptr_fqdn_replacement_pattern*]
#    Regular expression that matches PTR records to be replaced
#
class openstack::designate::dns_floating_ip_updater(
    String $floating_ip_ptr_zone,
    String $floating_ip_ptr_fqdn_matching_regex,
    String $floating_ip_ptr_fqdn_replacement_pattern,
) {

    # Also requires openstack::clientpackages
    require_package('python-ipaddress')

    $config = {
        'floating_ip_ptr_zone'                     => $floating_ip_ptr_zone,
        'floating_ip_ptr_fqdn_matching_regex'      => $floating_ip_ptr_fqdn_matching_regex,
        'floating_ip_ptr_fqdn_replacement_pattern' => $floating_ip_ptr_fqdn_replacement_pattern,
        'retries' => 2,
        'retry_interval' => 120,
    }

    file { '/etc/wmcs-dns-floating-ip-updater.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => ordered_yaml($config),
    }

    file { '/usr/local/sbin/wmcs-dns-floating-ip-updater':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0750',
        source  => 'puppet:///modules/openstack/designate/wmcs-dns-floating-ip-updater.py',
        require => Package['python-ipaddress']
    }

    if os_version('debian >= jessie') {

        # TODO: Remove after change is applied
        cron { 'floating-ip-ptr-record-updater':
            ensure => absent,
            user   => 'root',
        }

        systemd::timer::job { 'designate_floating_ip_ptr_records_updater':
            ensure                    => present,
            description               => 'Designate Floating IP PTR records updater',
            command                   => '/usr/local/sbin/wmcs-dns-floating-ip-updater',
            interval                  => {
                'start'    => 'OnCalendar',
                'interval' => '*-*-* *:00/15:00', # Every 15 minutes
            },
            max_runtime_seconds       => 890,  # kill if running after 14m50s
            logging_enabled           => false,
            monitoring_enabled        => true,
            monitoring_contact_groups => 'wmcs-team',
            user                      => 'root',
            require                   => [
                File['/usr/local/sbin/wmcs-dns-floating-ip-updater'],
                File['/etc/wmcs-dns-floating-ip-updater.yaml'],
            ],
        }
    }
}
