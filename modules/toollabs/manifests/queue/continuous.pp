# manage continuous queue

class toollabs::queue::continuous {

    $hostlist = '@general'

    gridengine::queue { 'continuous':
        config => 'toollabs/gridengine/queue-continuous.erb',
    }
}
