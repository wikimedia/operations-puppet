#

class {'::postgresql::slave':
    master_server    => 'test',
    replication_pass => 'pass',
}
