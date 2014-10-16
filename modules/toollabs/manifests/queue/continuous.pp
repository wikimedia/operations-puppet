# Class: toollabs::queue::continuous
#
#
class toollabs::queue::continuous {

    $hostlist = '@general'

    gridengine::queue { 'continuous':
        content => template('toollabs/gridengine/queue-continuous.erb'),
    }

}
