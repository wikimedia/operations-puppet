# @summary profiletp configure the compiler nodes
class profile::puppet_compiler (
    Boolean                $puppetdb_proxy = lookup('profile::puppet_compiler::puppetdb_proxy'),
    Optional[Stdlib::Host] $puppetdb_host  = lookup('profile::puppet_compiler::puppetdb_host'),
    Optional[Stdlib::Port] $puppetdb_port  = lookup('profile::puppet_compiler::puppetdb_port'),
) {
    requires_realm('labs')

    include profile::openstack::base::puppetmaster::enc_client
    class {'puppet_compiler': }
    class { 'puppetmaster::puppetdb::client':
        hosts => [$facts['fqdn']],
    }
    # puppetdb configuration
    file { "${puppet_compiler::vardir}/puppetdb.conf":
        source => '/etc/puppet/puppetdb.conf',
        owner  => $puppet_compiler::user,
    }
    if $puppetdb_proxy {
        $ssldir = "${puppet_compiler::vardir}/ssl"
        $ssl_settings = ssl_ciphersuite('nginx', 'strong')

        nginx::site {'puppetdb-proxy':
            content => template('profile/puppet_compiler/puppetdb-proxy.erb'),
        }
        ferm::service {'puppetdb-proxy':
            proto  => 'tcp',
            port   => 'https',
            prio   => '30',
            srange => '$LABS_NETWORKS'
        }
    }
}
