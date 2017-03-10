# == Class role::analytics_cluster::refinery::job::guard
# Configures a cron job that runs analytics/refinery/source guards daily and
# sends out an email upon issues
#
class role::analytics_cluster::refinery::job::guard {
    require ::role::analytics_cluster::refinery::source

    include ::maven

    cron { 'refinery source guard':
        command     => "${role::analytics_cluster::refinery::source::path}/guard/run_all_guards.sh --rebuild-jar --quiet",
        environment => 'MAILTO=otto@wikimedia.org',
        user        => $role::analytics_cluster::refinery::source::user,
        hour        => 15,
        minute      => 35,
    }
}