# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main nodes
class profile::zuul::main(
    String $ssl_password = lookup('profile::zuul::main::ssl_password'),
){
    # let zuul see and validate gerrit server ssh host keys
    # otherwise zuul will accept any key provided (T395938#10929023)
    # link into existing ssh_known_hosts populated by puppet
    file { '/var/lib/zuul/.ssh/known_hosts':
        ensure => 'link',
        target => '/etc/ssh/ssh_known_hosts',
    }

    # write the TLS passphrase to a file so we can point
    # zookeeper to it with ssl.keyStore.passwordPath
    file { '/etc/zookeeper/conf/zuul_tls':
        ensure  => 'file',
        content => $ssl_password,
        owner   => 'zookeeper',
        group   => 'zookeeper',
        mode    => '0440',
        require => Service['zookeeper'],
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

    $tls_paths = profile::pki::get_cert('zuul', 'zuul', {
        'owner'           => 'zookeeper',
        'notify_services' => ['zookeeper'],
    })

    $zookeeper_tls_cert = $tls_paths['cert']
    $zookeeper_tls_key = $tls_paths['key']
    $zookeeper_tls_ca = $tls_paths['chain']
    # $tls_outdir = dirname($tls_paths['cert'])

    sslcert::x509_to_pkcs12 { 'zookeeper_zuul_keystore' :
        owner       => 'zookeeper',
        group       => 'zookeeper',
        public_key  => $zookeeper_tls_cert,
        private_key => $zookeeper_tls_key,
        certfile    => $zookeeper_tls_ca,
        outfile     => '/etc/zookeeper/conf/zookeeper_zuul.keystore.p12',
        password    => $ssl_password,
        notify      => Service['zookeeper'],
    }
}
