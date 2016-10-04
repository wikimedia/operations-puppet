# == Class: role::toollabs::node::web::generic
# 
# Sets up a node for running generic webservices.
# Currently explicitly supports nodejs
class role::toollabs::node::web::generic inherits role::toollabs::node::web {
    class { 'toollabs::queues':
        queues => [ 'webgrid-generic' ],
    }

    # uwsgi python support
    package {[
        'uwsgi',
        'uwsgi-plugin-python',
        'uwsgi-plugin-python3',
    ]:
        ensure => latest,
    }

    # tomcat support
    package { [ 'tomcat7-user', 'xmlstarlet' ]:
        ensure => latest,
    }
}
