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

    package {[
        'uwsgi',
        'uwsgi-plugin-python',
        'uwsgi-plugin-python3',
    ]:
        ensure => latest,
    }

    class { 'toollabs::queues':
        queues => [ 'webgrid-uwsgi' ],
    }

    # Exact same file. The script knows to perform different actions based on
    # what it is called
    file { '/usr/local/bin/tool-uwsgi-python':
        source => 'puppet:///modules/toollabs/tool-uwsgi-python',
        mode   => '0555',
    }

    file { '/usr/local/bin/tool-uwsgi-python3':
        source => 'puppet:///modules/toollabs/tool-uwsgi-python',
        mode   => '0555',
    }
}
