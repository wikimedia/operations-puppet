#

class { '::ganglia::web':
    rrdcached_socket => '/var/run/gweb.sock',
    gmetad_root      => '/var/lib/ganglia/',
}
