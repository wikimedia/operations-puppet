# == Class: toollabs::node::web::generic
# 
# Sets up a node for running generic webservices.
# Currently explicitly supports nodejs
class toollabs::node::web::generic inherits toollabs::node::web {
    class { 'toollabs::queues':
        queues => [ 'webgrid-generic' ],
    }

    file { '/usr/local/bin/tool-nodejs':
        source => 'puppet:///modules/toollabs/tool-nodejs',
        mode   => '0555',
    }

    file { '/usr/local/bin/tool-tomcat':
        source => 'puppet:///modules/toollabs/tool-tomcat',
        mode   => '0555',
    }
}
