# SPDX-License-Identifier: Apache-2.0
#
# A new implementation of a current zuul system for CI, 2026. (T393873)
# Base class / common setup for
# zuul nodes of different types such as main, executor and worker.
#
class profile::zuul::base(
    String $gerrit_user             = lookup('profile::zuul::base::gerrit_user'),
    String $gerrit_sshkey           = lookup('profile::zuul::base::gerrit_sshkey'),
    Array[Stdlib::Fqdn] $main_nodes = lookup('zuul_main_nodes'),
    Stdlib::Fqdn $mysql_host        = lookup('profile::zuul::base::mysql_host'),
    Stdlib::Unixpath $tls_config_dir = lookup('profile::zuul::base::tls_config_dir'),
    String $tls_password = lookup('profile::zuul::main::tls_password'),
    String $zookeeper_tls_fullchain = lookup('profile::zuul::base::zookeeper_tls_fullchain'),
){

    # local zookeeper, outside of docker, coordinates
    $zookeeper_server_ip = dnsquery::lookup($main_nodes[0])[0]

    # passwords for: database, gerrit and auth operator
    include ::passwords::mysql::zuul
    $mysql_pass = $::passwords::mysql::zuul::password

    include ::passwords::zuul::gerrit
    $gerrit_pass = $::passwords::zuul::gerrit::password

    include ::passwords::zuul::auth_operator
    $auth_operator_secret = $::passwords::zuul::auth_operator::secret

    # certificate for mTLS between zuul components and zookeeper
    $tls_paths = profile::pki::get_cert('zuul', 'zuul', {
        'owner'  => 'zuul',
        'outdir' => $tls_config_dir,
    })

    $zuul_tls_cert = $tls_paths['cert']
    $zuul_tls_key  = $tls_paths['key']
    $zuul_tls_ca   = $tls_paths['chain']

    # the zuul user's home
    wmflib::dir::mkdir_p('/var/lib/zuul', {
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    })

    # expected location of keys for zuul-executor
    wmflib::dir::mkdir_p('/var/lib/zuul/.ssh', {
        owner   => 'zuul',
        group   => 'zuul',
        require => File['/var/lib/zuul'],
    })

    # expected location of keys to connect to gerrit
    $ssh_base_dir = dirname($gerrit_sshkey)
    wmflib::dir::mkdir_p($ssh_base_dir, {
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    })

    # ssh key for zuul to auth with Gerrit
    file { $gerrit_sshkey:
        owner     => 'zuul',
        group     => 'zuul',
        mode      => '0400',
        content   => secret('gerrit/zuul_gerrit_ed25519'),
        show_diff => false,
    }

    # because we use docker
    ensure_packages(['apparmor-utils'])

    # one global zuul config across main and executor nodes
    wmflib::dir::mkdir_p('/etc/zuul', {
        owner   => 'zuul',
        group   => 'zuul',
        require => User['zuul'],
    })

    file { '/etc/zuul/zuul.conf':
        ensure  => file,
        owner   => 'zuul',
        group   => 'zuul',
        mode    => '0440',
        content => template('profile/zuul/zuul.conf.erb'),
        require => File['/etc/zuul'],
    }

    # standard logging
    rsyslog::conf { 'zuul':
        content  => file('zuul/rsyslog.conf'),
        priority => 20,
    }

    # allow traffic between zuul services in docker and zookeeper outside of it
    firewall::service { 'zuul-docker-to-zookeeper':
        proto  => 'tcp',
        port   => 2281,
        srange => ['172.17.0.0/16'],
    }
}
