#

class { 'ganglia_new::gmetad::rrdcached':
    rrdpath       => '/var/lib/ganglia',
    gmetad_socket => '/var/run/mysock1',
    gweb_socket   => '/var/run/mysock2',
}
