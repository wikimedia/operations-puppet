# XXX support additional storage policies
class swift_new (
    $cluster = $swift_new::params::cluster,
    $hash_path_suffix,
) {
    include webserver::base

    # Recommendations from Swift -- see <http://tinyurl.com/swift-sysctl>.
    sysctl::parameters { 'swift_performance':
        values => {
            'net.ipv4.tcp_syncookies'             => '0',
            'net.ipv4.tcp_tw_recycle'             => '1',  # disable TIME_WAIT
            'net.ipv4.tcp_tw_reuse'               => '1',
            'net.ipv4.netfilter.ip_conntrack_max' => '262144',
        },
    }

    package { [
        'swift',
        'python-swift',
        'python-swiftclient',
        'python-statsd',
        'parted',
    ]:
        ensure => 'present',
    }

    File {
        owner => 'swift',
        group => 'swift',
        mode  => '0440',
    }

    file { '/etc/swift':
        ensure  => 'directory',
        require => Package['swift'],
        recurse => true,
    }

    file { '/etc/swift/swift.conf':
        ensure  => present,
        require => Package['swift'],
        content => template('swift_new/swift.conf.erb'),
    }

    file { '/var/cache/swift':
        ensure  => 'directory',
        require => Package['swift'],
        mode    => '0755',
    }
}
