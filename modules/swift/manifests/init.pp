# SPDX-License-Identifier: Apache-2.0

class swift (
    String $hash_path_suffix,
    Boolean $storage_policies = true,
) {
    # Recommendations from Swift -- see <http://tinyurl.com/swift-sysctl>.
    sysctl::parameters { 'swift_performance':
        values => {
            'net.ipv4.tcp_syncookies'      => '0',
            # Disable TIME_WAIT
            'net.ipv4.tcp_tw_reuse'        => '1',

            # Other general network/TCP tuning

            # Increase the number of ephemeral ports
            'net.ipv4.ip_local_port_range' => [ 1024, 65535 ],

            # Recommended to increase this for 1000 BT or higher
            'net.core.netdev_max_backlog'  => 30000,

            # Increase the queue size of new TCP connections
            'net.core.somaxconn'           => 4096,
            'net.ipv4.tcp_max_syn_backlog' => 262144,
            'net.ipv4.tcp_max_tw_buckets'  => 360000,

            # Decrease FD usage
            'net.ipv4.tcp_fin_timeout'     => 3,
            'net.ipv4.tcp_max_orphans'     => 262144,
            'net.ipv4.tcp_synack_retries'  => 2,
            'net.ipv4.tcp_syn_retries'     => 2,
        },
    }

    # Got removed in Linux 4.12 with
    # https://git.kernel.org/linus/4396e46187ca5070219b81773c4e65088dac50cc
    if debian::codename::eq('stretch') {
        sysctl::parameters { 'swift_performance_rw_recycle':
            values => {
                'net.ipv4.tcp_tw_recycle'      => '1',
            },
        }
    }

    if debian::codename::ge('bullseye') {
        $python_swift_pkg = 'python3-swift'
    } else {
        $python_swift_pkg = 'python-swift'
    }

    # Use 'package' as opposed to ensure_packagess to avoid dependency cycles
    package { [
        'swift',
        $python_swift_pkg,
        'python3-swiftclient',
        'parted',
    ]:
        ensure => present,
    }

    ensure_packages(['python3-statsd'])

    file {
        default:
            owner   => 'swift',
            group   => 'swift',
            mode    => '0440',
            require => Package['swift'];
        '/etc/swift':
            ensure  => directory,
            recurse => true;
        '/etc/swift/swift.conf':
            ensure  => file,
            content => template('swift/swift.conf.erb');
        '/var/cache/swift':
            ensure => directory,
            mode   => '0755';
        # Create swift user home. Once T123918 is resolved this should be moved as
        # part of a user resource declaration.
        '/var/lib/swift':
            ensure => directory,
            mode   => '0755',
    }

    if !defined(File['/srv/log']) {
        file { '/srv/log':
            ensure => 'directory',
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
            before => Package['swift'],
        }
    }

    file { '/srv/log/swift':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        before => Package['swift'],
    }

    # Move log directory to bigger /srv
    file { '/var/log/swift':
        ensure  => link,
        force   => true,
        target  => '/srv/log/swift',
        require => File['/srv/log/swift'],
        before  => Package[$python_swift_pkg],
    }

    logrotate::conf { 'swift':
        ensure => present,
        source => 'puppet:///modules/swift/swift.logrotate.conf',
    }

    rsyslog::conf { 'swift':
        source   => 'puppet:///modules/swift/swift.rsyslog.conf',
        priority => 40,
        require  => File['/var/log/swift'],
    }

    # Used to ban logs both from local disk and centrallog syslog hosts
    rsyslog::conf { 'swift-pre-centrallog':
        source   => 'puppet:///modules/swift/swift.rsyslog-pre-centrallog.conf',
        priority => 20,
    }
}
