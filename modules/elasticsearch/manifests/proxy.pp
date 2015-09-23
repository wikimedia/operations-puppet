# == Class elasticsearch::proxy
# Sets up a simple nginx reverse proxy.
# This must be included on the same node as an elasticsearch server
#
# This depends on the ferm and nginx module's from WMF operations/puppet/modules.
#
class elasticsearch::proxy {
    nginx::site { 'elasticsearch-proxy':
        source => 'file:///modules/elasticsearch/labs-es-proxy.nginx.conf'
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => 80,
    }
}
