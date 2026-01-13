# SPDX-License-Identifier: Apache-2.0
# === Class: profile::ganeti
#
# This profile configures Ganeti's keys, RAPI users, and configures
# the firewall on the host.
#
# Actions:
#
# Requires:
#
# Sample Usage:
#       include profile::ganeti
#
# === Parameters
#
# [*nodes*]
#   A list of Ganeti nodes in this particular cluster.
#
# [*rapi_nodes*]
#   A list of nodes to open the RAPI port to.
#
# [*rapi_certificate*]
#   A string containing the name of the certificate to use
#
# [*rapi_ro_user*]
#   A string containing the name of the read-only user to configure in RAPI.
#
# [*rapi_ro_password*]
#   A string containing the password for the aforementioned user.
#
# [*critical_memory*]
#   Percentage of memory (0-100) which, if using over it, it will throw a
#   critical alert due to memory pressure. It must be higher than warning
#   memory.
#
# [*warning_memory*]
#   Percentage of memory (0-100) which, if using over it, it will throw a
#   warning alert due to memory pressure. It must be lower than
#   critical_memory.
#
# [*routed*]
#   If Ganeti is used in routed (L3) mode or not.
#   See https://wikitech.wikimedia.org/wiki/Ganeti#Routed_Ganeti
#
# [*tap_ip4*]
#   Required in routed mode only, specify the public and private IPv4 assigned to all the VM facing interfaces.
#   IPv6 automatically uses the link-local address.
#
# [*tftp_servers*]
#   Dictionary of DHCP servers (as they're the same as TFTP servers)
#   keyed by site.

class profile::ganeti (
    Array[Stdlib::Fqdn]                         $nodes              = lookup('profile::ganeti::nodes'),
    Array[Stdlib::Fqdn]                         $rapi_nodes         = lookup('profile::ganeti::rapi_nodes'),
    String                                      $rapi_certificate   = lookup('profile::ganeti::rapi::certificate'),
    Optional[String]                            $rapi_ro_user       = lookup('profile::ganeti::rapi::ro_user',
                                                                              { default_value => undef }),
    Optional[String]                            $rapi_ro_password   = lookup('profile::ganeti::rapi::ro_password',
                                                                              { default_value => undef }),
    Integer[0, 100]                             $critical_memory    = lookup('profile::ganeti::critical_memory'),
    Integer[0, 100]                             $warning_memory     = lookup('profile::ganeti::warning_memory'),
    Boolean                                     $routed             = lookup('profile::ganeti::routed'),
    Optional[Hash[String, Stdlib::IP::Address]] $tap_ip4            = lookup('profile::ganeti::tap_ip4',
                                                                              { default_value => undef }),
    Hash[Wmflib::Sites, Stdlib::IP::Address]    $tftp_servers       = lookup('profile::installserver::dhcp::tftp_servers'),
    Boolean                                     $manage_known_hosts = lookup('profile::ganeti::manage_known_hosts', { default_value => false }),
    Optional[String]                            $cluster_ssh_key    = lookup('profile::ganeti::cluster_ssh_key',
                                                                              { default_value => undef }),
) {

    if $manage_known_hosts and $cluster_ssh_key == undef {
        fail('You need to configure the cluster SSH pubkey when using the managed known_hosts')
    }

    class { 'ganeti':
        certname => $rapi_certificate,
    }

    class { 'ganeti::prometheus':
        rapi_endpoint    => $rapi_certificate,
        rapi_ro_user     => $rapi_ro_user,
        rapi_ro_password => $rapi_ro_password,
    }

    # Ganeti needs intracluster SSH root access
    # DSS+RSA keys in here, but note that DSS is deprecated
    ssh::userkey { 'root-ganeti':
        ensure => present,
        user   => 'root',
        skey   => 'ganeti',
        source => 'puppet:///modules/profile/ganeti/ganeti.pub',
    }

    # The RSA private key
    file { '/root/.ssh/id_rsa':
        ensure    => present,
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('ganeti/id_rsa'),
        show_diff => false,
    }
    # This is here for completeness
    file { '/root/.ssh/id_rsa.pub':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/profile/ganeti/id_rsa.pub',
    }

    motd::script { 'ganeti-master-motd':
        ensure => present,
        source => 'puppet:///modules/profile/ganeti/motd',
    }

    if defined('$rapi_ro_user') and defined('$rapi_ro_password') {
        # Authentication for RAPI (for now just a single read-only user)
        $ro_password_hash = md5("${rapi_ro_user}:Ganeti Remote API:${rapi_ro_password}")
        $real_content = "${rapi_ro_user} {HA1}${ro_password_hash} read\n"
    } else {
        # Provide a blank authentication file for the RAPI server (no users will be defined, thus denying all)
        $real_content = ''
    }

    file { '/var/lib/ganeti/rapi':
        ensure => directory,
        owner  => 'gnt-rapi',
        group  => 'gnt-masterd',
        mode   => '0750',
    }

    file { '/var/lib/ganeti/rapi/users':
        ensure  => present,
        owner   => 'gnt-rapi',
        group   => 'gnt-masterd',
        mode    => '0640',
        content => $real_content,
        require => Class['ganeti'],
    }

    # Allow SSH between ganeti cluster members
    firewall::service { 'ganeti_ssh_cluster':
        proto  => 'tcp',
        port   => 22,
        srange => $nodes,
    }

    # RAPI is the API of ganeti
    firewall::service { 'ganeti_rapi_cluster':
        proto  => 'tcp',
        port   => 5080,
        srange => $nodes + $rapi_nodes,
    }

    # Ganeti noded is responsible for all cluster/node actions
    firewall::service { 'ganeti_noded_cluster':
        proto  => 'tcp',
        port   => 1811,
        srange => $nodes,
    }

    # Ganeti confd provides a HA and fast way to query cluster configuration
    firewall::service { 'ganeti_confd_cluster':
        proto  => 'udp',
        port   => 1814,
        srange => $nodes,
    }

    # Ganeti mond is the monitoring daemon. Data is available via port 1815
    firewall::service { 'ganeti_mond_cluster':
        proto  => 'tcp',
        port   => 1815,
        srange => $nodes,
    }

    # DRBD is used for HA of disk images. Port range for ganeti is 11000-14999
    firewall::service { 'ganeti_drbd':
        proto      => 'tcp',
        port_range => [11000,14999],
        srange     => $nodes,
    }

    # Migration is done over TCP port
    firewall::service { 'ganeti_migration':
        proto  => 'tcp',
        port   => 8102,
        srange => $nodes,
    }

    file { '/usr/local/sbin/ganeti_rebalance':
        ensure => present,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/ganeti/ganeti_rebalance.sh',
    }

    # If ganeti_cluster fact is not defined, the node has not been added to a
    # cluster yet, so don't monitor
    if $facts['ganeti_cluster'] {

        # Service monitoring
        nrpe::monitor_service{ 'ganeti-noded':
            description    => 'ganeti-noded running',
            nrpe_command   => '/usr/lib/nagios/plugins/check_procs -w 1:2 -c 1:2 -u root -C ganeti-noded',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Ganeti',
            migration_task => 'T357099',
        }

        prometheus::blackbox::check::tcp { 'ganeti-noded':
            port          => 1811,
            ip_families   => ['ip4',],
            probe_runbook => 'https://wikitech.wikimedia.org/wiki/Ganeti',
        }


        nrpe::monitor_service{ 'ganeti-confd':
            description    => 'ganeti-confd running',
            nrpe_command   => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-confd -C ganeti-confd',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Ganeti',
            migration_task => 'T357099',
        }

        # Memory monitoring
        ensure_packages( 'monitoring-plugins-contrib' )  # for pmp-check-unix-memory

        if $facts['ganeti_master'] == $facts['fqdn'] {
            nrpe::monitor_service { "https-gnt-rapi-${::site}":
                description    => "HTTPS Ganeti RAPI ${::site}",
                nrpe_command   => "/usr/lib/nagios/plugins/check_http -H ${facts['ganeti_cluster']} -p 5080 -S -e 401",
                notes_url      => 'https://www.mediawiki.org/wiki/Ganeti#RAPI_daemon',
                migration_task => 'T350694',
            }

            nrpe::monitor_service{ 'ganeti-wconfd':
                description    => 'ganeti-wconfd running',
                nrpe_command   => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-masterd -C ganeti-wconfd',
                notes_url      => 'https://wikitech.wikimedia.org/wiki/Ganeti',
                migration_task => 'T357099',
            }
        }

        if $manage_known_hosts {
            $known_hosts = ganeti::known_hosts($facts['ganeti_cluster'])

            file { '/var/lib/ganeti/known_hosts':
                ensure  => present,
                mode    => '0644',
                owner   => 'gnt-masterd',
                group   => 'gnt-masterd',
                content => sprintf('%s%s', $known_hosts , $cluster_ssh_key),
            }
        }

        # Run a montly rebalancing for all nodegroups
        # Note: We only run this on the first Wednesday of the month
        # This should only be run on the master and absented from all other
        # nodes
        $hbal_presence = $facts['ganeti_master'] ? {
            $facts['fqdn'] => absent,
            default        => absent,
        }
        systemd::timer::job { 'monthly_ganeti_rebalance':
            ensure      => $hbal_presence,
            description => 'Run a monthly rebalance of Ganeti instances',
            command     => '/usr/local/sbin/ganeti_rebalance',
            user        => 'root',
            interval    => [{
                'start'    => 'OnCalendar',
                'interval' => 'Wed *-*-01,02,03,04,05,06,07 11:47:00',
                }
            ]
        }
    }
    if $routed {
        if $tap_ip4 == undef {
            fail('In routed mode, `profile::ganeti::tap_ip4` must be defined.')
        }

        ensure_packages('dnsmasq')
        file { '/etc/dnsmasq.conf':
            content      => template('profile/ganeti/dnsmasq.conf.erb'),
            notify       => Exec['dnsmasq-restart'],
            require      => Package['dnsmasq'],
            validate_cmd => '/usr/sbin/dnsmasq --test --conf-file=%',
        }
        exec { 'dnsmasq-restart':
            command     => '/usr/sbin/dnsmasq --test && /bin/systemctl restart dnsmasq',
            refreshonly => true,
            require     => Package['dnsmasq'],
        }

        nftables::file { 'ganeti-forward-chain':
            order   => 101,
            content => file('profile/ganeti/ganeti-forward.nft'),
        }

        nftables::rules { 'ganeti_vms_in':
            desc  => 'Traffic from the VMs towards the hypervisor (and not through)',
            chain => 'input',
            prio  => 10,
            rules => ['tcp dport { 179 } iifname "tap*" accept', # BGP
                      'udp dport { 67 } iifname "tap*" accept', # DHCP request
                      ],
        }
        # Below is an adaptation of homer-public:policies/common-sandbox.yaml
        nftables::rules { 'ganeti_vms_forward':
            desc  => 'Traffic from the VMs through the hypervisor',  # mostly to restrict sandbox traffic
            chain => 'forward',
            prio  => 10,
            rules => ['ct state related,established accept', # Generic allow established
                      'ip protocol icmp accept', # Generic allow ICMP
                      'meta l4proto ipv6-icmp accept',
                      'ip saddr @SANDBOX_NETWORKS_ipv4 udp dport { 53 } iifname "tap*" accept',  # allow DNS
                      'ip6 saddr @SANDBOX_NETWORKS_ipv6 udp dport { 53 } iifname "tap*" accept',
                      'ip saddr @SANDBOX_NETWORKS_ipv4 ip daddr @INTERNAL_ipv4 iifname "tap*" drop',  # drop private
                      'ip6 saddr @SANDBOX_NETWORKS_ipv6 ip6 daddr @INTERNAL_ipv6 iifname "tap*" drop',
                      'ip saddr @SANDBOX_NETWORKS_ipv4 ip daddr @PRODUCTION_NETWORKS_ipv4  iifname "tap*" drop',  # drop prod
                      'ip6 saddr @SANDBOX_NETWORKS_ipv6 ip6 daddr @PRODUCTION_NETWORKS_ipv6 iifname "tap*" drop',
                      # default accept
                      ],
        }

        # TODO ideally get those from Netbox or data.yaml
        $v6_prefixes = $::site ? {
            'codfw' => {'private' => '2620:0:860:140', 'public' => '2620:0:860:5', 'sandbox' => '2620:0:860:201'},
            'eqiad' => {'private' => '2620:0:861:140', 'public' => '2620:0:861:5', 'sandbox' => '2620:0:861:202'},
            'esams' => {'private' => '2a02:ec80:300:103', 'public' => '2a02:ec80:300:3', 'sandbox' => '2a02:ec80:300:202'},
            'magru' => {'private' => '2a02:ec80:700:103', 'public' => '2a02:ec80:700:3', 'sandbox' => '2a02:ec80:700:201'},
        }
        # Override the Package provided net-common script
        file { '/usr/lib/ganeti/3.0/usr/lib/ganeti/net-common':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('profile/ganeti/net-common.erb'),
        }

        sysctl::parameters { 'primary-nic-ip-forward':
            values => {
                'net.ipv4.ip_forward'                                     => 1,
                "net.ipv4.conf.${$facts['interface_primary']}.ip_forward" => 1,
                "net.ipv6.conf.${$facts['interface_primary']}.accept_ra"  => 2,
                "net.ipv6.conf.${$facts['interface_primary']}.forwarding" => 1,
                'net.ipv6.conf.all.forwarding'                            => 1,
            },
        }
        sysctl::parameters { 'disable-v4-redirects':
            values => {
                'net.ipv4.conf.all.send_redirects'     => 0,
                'net.ipv4.conf.default.send_redirects' => 0,
            },
        }

        # Unlike the legacy bridged mode routed packets are processed by hypervisor
        # local firewall, so we need to not re-mark DSCP in packets from VMs
        nftables::rules { 'trust-vm-dscp':
            desc  => 'Skip DSCP marking rules in postrouting for packets from VMs',
            chain => 'postrouting',
            prio  => 5,
            rules => ['iifname "tap*" return'],
        }

        class { 'bird':
            bfd               => false,
            do_ipv6           => true,
            multihop          => false,
            config_template   => 'bird/bird_ganeti.conf.erb',
            routed_ganeti_apt => true,
        }
    } else {
        if debian::codename::ge('bookworm') {
            ensure_packages('bridge-utils')
        }
    }
}
