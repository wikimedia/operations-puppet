# Nova-network is the network service currently used in Labs; some day soon
#  we hope to replace it with Neutron.
# http://docs.openstack.org/openstack-ops/content/nova-network-deprecation.html
class openstack::nova::network($novaconfig, $openstack_version=$::openstack::version) {
    include ::openstack::repo

    $tftp_host = 'install1002.wikimedia.org'

    package {  [ 'nova-network', 'dnsmasq' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    # dnsmasq is run manually by nova-network, we don't want the service running
    service { 'dnsmasq':
        ensure  => stopped,
        enable  => false,
        require => Package['dnsmasq'];
    }

    $nova_dnsmasq_aliases = {
        # eqiad
        'deployment-cache-text04'   => {public_ip  => '208.80.155.135',
                                        private_ip => '10.68.18.103' },
        'deployment-cache-upload04' => {public_ip  => '208.80.155.136',
                                        private_ip => '10.68.18.109' },
        'deployment-stream'         => {public_ip  => '208.80.155.138',
                                        private_ip => '10.68.17.106' },
        'relic'                     => {public_ip  => '208.80.155.197',
                                        private_ip => '10.68.16.162' },
        'tools-webproxy'            => {public_ip  => '208.80.155.131',
                                        private_ip => '10.68.21.49' },
        # A wide variety of hosts are reachable via a public web proxy.
        'labs_shared_proxy' => {public_ip  => '208.80.155.156',
                                private_ip => '10.68.21.68'},
    }

    $dnsconfig = hiera_hash('labsdnsconfig', {})
    $labs_metal = hiera('labs_metal',{})
    $recursor_ip = ipresolve($dnsconfig['recursor'],4)
    $recursor_secondary_ip = ipresolve($dnsconfig['recursor_secondary'],4)
    file { '/etc/dnsmasq-nova.conf':
        content => template("openstack/${openstack_version}/nova/dnsmasq-nova.conf.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['nova-network'],
    }

    sysctl::parameters { 'openstack':
        values   => {
            # Turn off IP filter
            'net.ipv4.conf.default.rp_filter' => 0,
            'net.ipv4.conf.all.rp_filter'     => 0,

            # Enable IP forwarding
            'net.ipv4.ip_forward'             => 1,
            'net.ipv6.conf.all.forwarding'    => 1,

            # Disable RA
            'net.ipv6.conf.all.accept_ra'     => 0,

            # Increase connection tracking size
            # and bucket since all of labs is
            # tracked on the network host
            'net.netfilter.nf_conntrack_max'  => 262144,
        },
        priority => 50,
    }

    file { '/etc/modprobe.d/nf_conntrack.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/base/firewall/nf_conntrack.conf',
        notify => Service['nova-network'],
    }

    file { '/usr/lib/nagios/plugins/check_conntrack':
        source => 'puppet:///modules/base/firewall/check_conntrack.py',
        mode   => '0755',
    }

    if $::hostname == hiera('labs_nova_network_host') {
        service { 'nova-network':
            ensure    => running,
            subscribe => File['/etc/nova/nova.conf'],
            require   => Package['nova-network'];
        }

        nrpe::monitor_service { 'check_nova_network_process':
            description  => 'nova-network process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-network'",
            critical     => true,
        }

        nrpe::monitor_service { 'conntrack_table_size':
            ensure        => 'present',
            description   => 'Check size of conntrack table',
            nrpe_command  => '/usr/lib/nagios/plugins/check_conntrack 80 90',
            require       => File['/usr/lib/nagios/plugins/check_conntrack'],
            contact_group => 'admins',
        }
    } else {
        service { 'nova-network':
            ensure  => stopped,
            require => Package['nova-network'];
        }
    }
}
