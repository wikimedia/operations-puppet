# == Class: profile::toolforge::grid::node::web::generic
# 
# Sets up a node for running generic webservices.
# Currently explicitly supports nodejs
#
class profile::toolforge::grid::node::web::generic(
    $collectors = lookup('profile::toolforge::grid::base::collectors'),
) {
    include profile::toolforge::grid::node::web
    # TODO: once exec nodes from the eqiad.wmflabs generation are gone, return to using $facts['fqdn']
    sonofgridengine::join { "queues-${facts['hostname']}.${::labsproject}.eqiad1.wikimedia.cloud":
        sourcedir => "${collectors}/queues",
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

    $tomcat_package = debian::codename() ? {
        'buster'  => 'tomcat9-user',
        default   => fail('unsupported debian version'),
    }

    package { [ $tomcat_package, 'xmlstarlet' ]:
        ensure => latest,
    }
}
