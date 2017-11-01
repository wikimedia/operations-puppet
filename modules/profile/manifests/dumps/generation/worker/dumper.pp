# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
class profile::dumps::generation::worker::dumper {
    class { 'snapshot::dumps::cron': user => 'datasets' }
}
