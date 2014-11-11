#

class { 'ganglia_new::gmetad':
    grid                => 'mygrid',
    rrd_rootdir         => '/var/lib/ganglia/rrds',
    rrdcached_socket    => '/var/lib/ganglia/rrds',
    authority           => 'http://localhost/ganglia',
    trusted_hosts       => ['192.168.10.10', '192.168.20.20']
}
