# this class is for snapshot hosts that run regular dumps
# meaning sql/xml dumps every couple of weeks or so
class role::snapshot::dumper {

    # config, stages files, dblists, html templates
    include snapshot::dumps

    # scap3 deployment of dump scripts
    include dataset::user
    include snapshot::deployment

    # cron job for running the dumps
    class { 'snapshot::dumps::cron': user => 'datasets' }
}
