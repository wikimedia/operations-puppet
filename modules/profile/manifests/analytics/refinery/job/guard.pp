# == Class profile::analytics::refinery::job::guard
# Configures a cron job that runs analytics/refinery/source guards daily and
# sends out an email upon issues
#
class role::profile::analytics::refinery {
    require ::profile::analytics::refinery::source

    include ::maven

    cron { 'refinery source guard':
        command     => "${profile::analytics::refinery::source::path}/guard/run_all_guards.sh --rebuild-jar --quiet",
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        user        => $profile::analytics::refinery::source::user,
        hour        => 15,
        minute      => 35,
    }
}