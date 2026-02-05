# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main nodes
class profile::zuul::main(
    String $tls_password = lookup('profile::zuul::main::tls_password'),
    Stdlib::Unixpath $tls_config_dir = lookup('profile::zuul::main::tls_config_dir'),
){

    # let zuul see and validate gerrit server ssh host keys
    # otherwise zuul will accept any key provided (T395938#10929023)
    # link into existing ssh_known_hosts populated by puppet
    file { '/var/lib/zuul/.ssh/known_hosts':
        ensure => 'link',
        target => '/etc/ssh/ssh_known_hosts',
    }

    profile::auto_restarts::service { 'envoyproxy': }

    file { '/var/www':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
    }

    file { '/var/www/zuul':
        ensure  => 'directory',
        owner   => 'zuul',
        group   => 'zuul',
        require => File['/var/www'],
    }

    # shared config dir for zookeeper-zuul mTLS
    file { $tls_config_dir:
        ensure  => 'directory',
        owner   => 'zookeeper',
        group   => 'zuul',
        mode    => '0550',
        require => [Package['zookeeper'],User['zuul']],
    }

    $tls_paths = profile::pki::get_cert('zuul', 'zuul', {
        'owner'           => 'zookeeper',
        'outdir'          => $tls_config_dir,
        'notify_services' => ['zookeeper'],
    })

    # use the 'chained' path (cert + CA) or we get "empty trust anchors"
    $zookeeper_tls_chained = $tls_paths['chained']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $tls_paths['chain']

    # convert to PKCS12 format for Java and let zookeeper read it
    sslcert::x509_to_pkcs12 { 'zookeeper_zuul_keystore' :
        owner       => 'zookeeper',
        group       => 'zookeeper',
        public_key  => $zookeeper_tls_chained,
        private_key => $zookeeper_tls_key,
        certfile    => $zookeeper_tls_ca,
        outfile     => "${tls_config_dir}/zookeeper_zuul.keystore.p12",
        password    => $tls_password,
        notify      => Service['zookeeper'],
    }
}
