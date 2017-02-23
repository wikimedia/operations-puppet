# == Class conftool
#
# Installs conftool, and creates a wrapper script that can be run in git as
# a post-receive hook.

class conftool(
    $ssl_dir     = '/var/lib/puppet/ssl',
    $use_ssl     = true,
    $auth        = true,
    $password    = undef,
    $hosts       = [
        'https://conf1001.eqiad.wmnet:2379',
        'https://conf1002.eqiad.wmnet:2379',
        'https://conf1003.eqiad.wmnet:2379',
    ],
    $tcpircbot_host = 'icinga.wikimedia.org',
    $tcpircbot_port = 9200,
    $namespace      = '/conftool'
    ) {
    require_package('python-conftool')

    require ::etcd::client::globalconfig

    file { '/etc/conftool':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/conftool/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ordered_yaml({
            hosts          => $hosts,
            tcpircbot_host => $tcpircbot_host,
            tcpircbot_port => $tcpircbot_port,
            driver_options => {
                allow_reconnect => true,
            },
            namespace      => $namespace,
        }),
    }

    if $auth {
        # Install basic auth data
        require ::etcd::auth::common
    }
}
