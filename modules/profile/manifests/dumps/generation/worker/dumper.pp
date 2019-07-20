# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
class profile::dumps::generation::worker::dumper(
    $runtype = lookup('profile::dumps::generation::worker::dumper::runtype'),
    $maxjobs = lookup('profile::dumps::generation::worker::dumper::maxjobs'),
) {
    class { 'snapshot::dumps::cron':
        user    => 'dumpsgen',
        maxjobs => $maxjobs,
        runtype => $runtype,
    }
}
