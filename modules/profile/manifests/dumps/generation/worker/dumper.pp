# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
# and no other tasks
class profile::dumps::generation::worker::dumper(
    $runtype = hiera('snapshot::dumps::runtype'),
) {
    class { 'snapshot::dumps::cron':
        user    => 'dumpsgen',
        maxjobs => '28',
        runtype => $runtype,
    }
}
