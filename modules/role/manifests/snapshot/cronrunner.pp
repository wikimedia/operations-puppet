# this class is for snapshot hosts that run various
# dump related cron jobs OTHER THAN the full xml/sql
# dumps
class role::snapshot::cronrunner {

    include role::snapshot::common

    if hiera('snapshot::cron::misc', false) {
        # cron jobs
        include role::snapshot::cronjobs

        system::role { 'role::snapshot::cronjobs':
            description => 'runner of misc dump-related cron jobs',
        }
    }
}
