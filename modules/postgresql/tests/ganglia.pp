#

include ::postgresql::server
class {'::postgresql::ganglia':
    pgstats_user => 'test',
    pgstats_pass => 'test',
}
