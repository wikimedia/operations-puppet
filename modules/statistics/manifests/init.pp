# wikistats configuration for generating
# stats.wikimedia.org data.
#
# TODO: puppetize clone of wikistats?
class statistics {

    include misc::statistics::base
    include statistics::packages
    include statistics::webserver

    # generates the new mobile pageviews report
    # and syncs the file PageViewsPerMonthAll.csv to stat1002
    cron { 'new mobile pageviews report':
        command  => "/bin/bash ${misc::statistics::base::working_path}/wikistats_git/pageviews_reports/bin/stat1-cron-script.sh",
        user     => 'stats',
        monthday => 1,
        hour     => 7,
        minute   => 20,
    }
}

