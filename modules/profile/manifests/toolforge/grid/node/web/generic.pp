# == Class: profile::toolforge::grid::node::web::generic
# 
# Sets up a node for running generic webservices.
# Currently explicitly supports nodejs
#
# filtertags: labs-project-tools
class profile::toolforge::grid::node::web::generic {
    include profile::toolforge::grid::node::web

    sonofgridengine::join { "queues-${::fqdn}":
        sourcedir => "${toollabs::collectors}/queues",
        list      => [ 'webgrid-generic' ],
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
