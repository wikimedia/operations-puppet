# SPDX-License-Identifier: Apache-2.0
# https://www.rabbitmq.com/
#
# User MAC's are not handled by Puppet
#
# Adding a user
#  rabbitmqctl add_user <user> <password>
# Changing a user password
#  rabbitmqctl change_password <user> <password>
#
# Setting tags for user "<user>" to [administrator] ...
#  rabbitmqctl set_user_tags <user> administrator
# All permissions example
#  rabbitmqctl set_permissions -p / <user> ".*" ".*" ".*"
#
# The management plugin may be desired
#  rabbitmq-plugins enable rabbitmq_management

class rabbitmq(
    $running = true,
    $file_handles = '1024',
    $erlang_cookie = '',
    Integer $heartbeat_timeout = 60,
    Optional[Stdlib::Unixpath] $tls_key_file = undef,
    Optional[Stdlib::Unixpath] $tls_cert_file = undef,
    Optional[Stdlib::Unixpath] $tls_ca_file = undef,
) {

    package { [ 'rabbitmq-server' ]:
        ensure  => 'present',
    }

    file { '/etc/default/rabbitmq-server':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('rabbitmq/rabbitmq-server.default.erb'),
        require => Package['rabbitmq-server'],
        notify  => Service['rabbitmq-server'],
    }

    file { '/usr/local/sbin/rabbitmqadmin':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        source  => 'puppet:///modules/rabbitmq/rabbitmqadmin.py',
        require => Package['rabbitmq-server'],
    }

    file { '/etc/rabbitmq/rabbitmq.config':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => epp(
            'rabbitmq/rabbitmq.config.epp',
            {
                'heartbeat_timeout' => $heartbeat_timeout,
                'tls_key_file'      => $tls_key_file,
                'tls_cert_file'     => $tls_cert_file,
                'tls_ca_file'       =>$tls_ca_file,
            }
        ),
        require => Package['rabbitmq-server'],
        notify  => Service['rabbitmq-server'],
    }

    file {'/usr/local/sbin/rabbit_random_guest':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0655',
        source  => 'puppet:///modules/rabbitmq/rabbit_random_guest.sh',
        require => Package['rabbitmq-server'],
    }

    # For multi-node setups, the two servers need to share
    #  this secret string.  For single-node setups
    #  we can just let rabbit generate whatever.
    if $erlang_cookie {
        file { '/var/lib/rabbitmq/.erlang.cookie':
            ensure  => 'present',
            owner   => 'rabbitmq',
            group   => 'rabbitmq',
            mode    => '0400',
            content => $erlang_cookie,
            require => Package['rabbitmq-server'],
        }
    }

    exec { 'invalidate_rabbitmq_guest_account':
        command     => '/usr/local/sbin/rabbit_random_guest',
        subscribe   => File['/usr/local/sbin/rabbit_random_guest'],
        refreshonly => true,
    }

    service { 'rabbitmq-server':
        ensure  => $running,
        require => Package['rabbitmq-server'],
    }
}
