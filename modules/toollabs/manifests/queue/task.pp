# Class: toollabs::queue::task
#
#
class toollabs::queue::task {

    $hostlist = '@general'

    gridengine::queue { 'task':
        content => template('toollabs/gridengine/queue-task.erb'),
    }

}
