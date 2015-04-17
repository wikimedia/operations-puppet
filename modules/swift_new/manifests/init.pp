# XXX support additional storage policies
class swift_new (
    $hash_path_suffix,
    $swift_cluster = $swift_new::params::swift_cluster,
) {
    # Recommendations from Swift -- see <http://tinyurl.com/swift-sysctl>.
    sysctl::parameters { 'swift_performance':
        values => {
            'net.ipv4.tcp_syncookies'             => '0',
            # Disable TIME_WAIT
            'net.ipv4.tcp_tw_recycle'             => '1',
            'net.ipv4.tcp_tw_reuse'               => '1',
            'net.ipv4.netfilter.ip_conntrack_max' => '262144',

            # Other general network/TCP tuning

            # Increase the number of ephemeral ports
            'net.ipv4.ip_local_port_range'        =>  [ 1024, 65535 ],

            # Recommended to increase this for 1000 BT or higher
            'net.core.netdev_max_backlog'         =>  30000,

            # Increase the queue size of new TCP connections
            'net.core.somaxconn'                  => 4096,
            'net.ipv4.tcp_max_syn_backlog'        => 262144,
            'net.ipv4.tcp_max_tw_buckets'         => 360000,

            # Decrease FD usage
            'net.ipv4.tcp_fin_timeout'            => 3,
            'net.ipv4.tcp_max_orphans'            => 262144,
            'net.ipv4.tcp_synack_retries'         => 2,
            'net.ipv4.tcp_syn_retries'            => 2,
        },
    }

    package { [
        'swift',
        'python-swift',
        'python-swiftclient',
        'parted',
    ]:
        ensure => present,
    }

    require_package('python-statsd')

    File {
        owner => 'swift',
        group => 'swift',
        mode  => '0440',
    }

    file { '/etc/swift':
        ensure  => directory,
        require => Package['swift'],
        recurse => true,
    }

    file { '/etc/swift/swift.conf':
        ensure  => present,
        require => Package['swift'],
        content => template('swift_new/swift.conf.erb'),
    }

    file { '/var/cache/swift':
        ensure  => directory,
        require => Package['swift'],
        mode    => '0755',
    }
}
