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
# [*ganeti3*]
#   Add the repository component with the 3.0 backport
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

class profile::ganeti (
    Array[Stdlib::Fqdn] $nodes         = lookup('profile::ganeti::nodes'),
    Array[Stdlib::Fqdn] $rapi_nodes    = lookup('profile::ganeti::rapi_nodes'),
    String $rapi_certificate           = lookup('profile::ganeti::rapi::certificate'),
    Optional[String] $rapi_ro_user     = lookup('profile::ganeti::rapi::ro_user',
                                                { default_value => undef }),
    Optional[String] $rapi_ro_password = lookup('profile::ganeti::rapi::ro_password',
                                                { default_value => undef }),
    Boolean $ganeti3                   = lookup('profile::ganeti::ganeti3'),
    Integer[0, 100] $critical_memory   = lookup('profile::ganeti::critical_memory'),
    Integer[0, 100] $warning_memory    = lookup('profile::ganeti::warning_memory'),
) {

    class { 'ganeti':
        certname => $rapi_certificate,
        ganeti3  => $ganeti3,
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
    file { '/var/lib/ganeti/rapi/users':
        ensure  => present,
        owner   => 'gnt-rapi',
        group   => 'gnt-masterd',
        mode    => '0640',
        content => $real_content,
        require => Class['ganeti'],
    }

    # Firewalling
    #

    $ganeti_ferm_nodes = join($nodes, ' ')
    $rapi_access = join(concat($nodes, $rapi_nodes), ' ')

    # Allow SSH between ganeti cluster members
    ferm::service { 'ganeti_ssh_cluster':
        proto  => 'tcp',
        port   => 'ssh',
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # RAPI is the API of ganeti
    ferm::service { 'ganeti_rapi_cluster':
        proto  => 'tcp',
        port   => 5080,
        srange => "@resolve((${rapi_access}))",
    }

    # Ganeti noded is responsible for all cluster/node actions
    ferm::service { 'ganeti_noded_cluster':
        proto  => 'tcp',
        port   => 1811,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Ganeti confd provides a HA and fast way to query cluster configuration
    ferm::service { 'ganeti_confd_cluster':
        proto  => 'udp',
        port   => 1814,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Ganeti mond is the monitoring daemon. Data is available via port 1815
    ferm::service { 'ganeti_mond_cluster':
        proto  => 'tcp',
        port   => 1815,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # DRBD is used for HA of disk images. Port range for ganeti is
    # 11000-14999
    ferm::service { 'ganeti_drbd':
        proto  => 'tcp',
        port   => '11000:14999',
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Migration is done over TCP port
    ferm::service { 'ganeti_migration':
        proto  => 'tcp',
        port   => 8102,
        srange => "@resolve((${ganeti_ferm_nodes}))",
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
            description  => 'ganeti-noded running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:2 -c 1:2 -u root -C ganeti-noded',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Ganeti',
        }

        nrpe::monitor_service{ 'ganeti-confd':
            description  => 'ganeti-confd running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-confd -C ganeti-confd',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Ganeti',
        }

        nrpe::monitor_service{ 'ganeti-mond':
            description  => 'ganeti-mond running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u root -C ganeti-mond',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Ganeti',
        }

        # Memory monitoring
        ensure_packages( 'nagios-plugins-contrib' )  # for pmp-check-unix-memory
        $check_path = '/usr/lib/nagios/plugins/pmp-check-unix-memory'
        $check_command = "${check_path} -c ${critical_memory} -w ${warning_memory}"
        nrpe::monitor_service { 'ganeti_memory':
            description  => 'Ganeti memory',
            nrpe_command => $check_command,
            require      => Package['nagios-plugins-contrib'],
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Ganeti#Memory_pressure',
        }



        if $facts['ganeti_master'] == $facts['fqdn'] {
            nrpe::monitor_service { "https-gnt-rapi-${::site}":
                description  => "HTTPS Ganeti RAPI ${::site}",
                nrpe_command => "/usr/lib/nagios/plugins/check_http -H ${facts['ganeti_cluster']} -p 5080 -S -e 401",
                notes_url    => 'https://www.mediawiki.org/wiki/Ganeti#RAPI_daemon',
            }

            nrpe::monitor_service{ 'ganeti-wconfd':
                description  => 'ganeti-wconfd running',
                nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-masterd -C ganeti-wconfd',
                notes_url    => 'https://wikitech.wikimedia.org/wiki/Ganeti',
            }
        }
        # Run a montly rebalancing for all nodegroups
        # Note: We only run this on the first Wednesday of the month
        # This should only be run on the master and absented from all other
        # nodes
        $hbal_presence = $facts['ganeti_master'] ? {
            $facts['fqdn'] => present,
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
}
