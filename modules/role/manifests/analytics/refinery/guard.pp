# == Class role::analytics::refinery::guard
# Configures a cron job that runs analytics/refinery/source guards daily and
# sends out an email upon issues
#
class role::analytics::refinery::guard {
    require role::analytics::refinery::source

    include ::maven

    cron { 'refinery source guard':
        command     => "${role::analytics::refinery::source::path}/guard/run_all_guards.sh --rebuild-jar --quiet",
        environment => 'MAILTO=otto@wikimedia.org',
        user        => $role::analytics::refinery::source::user,
        hour        => 15,
        minute      => 35,
    }
}
