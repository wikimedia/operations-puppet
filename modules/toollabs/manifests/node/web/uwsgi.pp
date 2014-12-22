# Class: toollabs::node::web::uwsgi
#
# This configures the compute node as an uwsgi web server
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::node::web::uwsgi inherits toollabs::node::web {

    package { [
        'uwsgi',
        'uwsgi-plugin-python',
        'uwsgi-plugin-python3',
    ]:
        ensure => latest,
    }


    class { 'toollabs::queues':
        queues => [ 'webgrid-uwsgi' ],
    }
}
