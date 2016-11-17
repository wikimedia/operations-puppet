# manage task queue

class toollabs::queue::task {

    $hostlist = '@general'

    gridengine::queue { 'task':
        config => 'toollabs/gridengine/queue-task.erb',
    }
}
