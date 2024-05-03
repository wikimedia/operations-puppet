# SPDX-License-Identifier: Apache-2.0
# @summary profiletp configure the compiler nodes
# @param puppetdb_proxy if we proxy db queries
# @param puppetdb_host puppetdb host
# @param puppetdb_port puppetdb port
class profile::puppet_compiler (
    Boolean                $puppetdb_proxy = lookup('profile::puppet_compiler::puppetdb_proxy'),
    Optional[Stdlib::Host] $puppetdb_host  = lookup('profile::puppet_compiler::puppetdb_host'),
    Optional[Stdlib::Port] $puppetdb_port  = lookup('profile::puppet_compiler::puppetdb_port'),
) {
    requires_realm('labs')

    include profile::openstack::base::puppetmaster::enc_client
    class { 'sslcert::dhparam': }
    class { 'puppet_compiler':
        group => 'wikidev',
    }
    class { 'puppetmaster::puppetdb::client':
        hosts => [$facts['networking']['fqdn']],
    }
    # puppetdb configuration
    file { "${puppet_compiler::vardir}/puppetdb.conf":
        source => '/etc/puppet/puppetdb.conf',
        owner  => $puppet_compiler::user,
    }
    # Files in this dir should only exist for the time it takes to do the pcc run
    systemd::timer::job { 'delete-canceled-pcc-run-dirs':
        ensure      => present,
        description => 'Clean up stale files from canceled PCC reports',
        command     => "/usr/bin/find ${puppet_compiler::workdir} -maxdepth 1 -type d -daystart -mtime +1 -exec rm -r {} \\;",
        user        => 'root',
        interval    => {'start' => 'OnUnitInactiveSec', 'interval' => '24h'},
    }
    if $puppetdb_proxy {
        $ssldir = "${puppet_compiler::vardir}/ssl"
        $ssl_settings = ssl_ciphersuite('nginx', 'strong')
        $docroot = $puppet_compiler::workdir

        nginx::site { 'puppet-compiler':
            content => template('profile/puppet_compiler/puppetdb-proxy.erb'),
        }
        ferm::service { 'puppetdb-proxy':
            proto  => 'tcp',
            port   => [443],
            prio   => 30,
            # this could be restricted to just localhost i think
            srange => '$LABS_NETWORKS',
        }
    }
}
