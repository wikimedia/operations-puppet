# this class is for snapshot hosts that run various
# dump related cron jobs OTHER THAN the full xml/sql
# dumps
class role::snapshot::cronrunner {
    include role::snapshot::common

    if hiera('snapshot::cron::misc', false) {
        # mw packages and dependencies, dataset server nfs mount
        include snapshot::dumps::packages

        # config, stages files, dblists, html templates
        include snapshot::dumps

        # scap3 deployment of dump scripts
        include dataset::user
        include snapshot::deployment

        # cron jobs
        include role::snapshot::cronjobs
    }
}
