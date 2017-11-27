# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
# and also other jobs
class profile::dumps::generation::worker::dumper_shared {
    class { 'snapshot::dumps::cron':
        user    => 'dumpsgen',
        maxjobs => '20',
    }
}
