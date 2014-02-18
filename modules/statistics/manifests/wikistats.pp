# wikistats configuration for generating
# stats.wikimedia.org data.
#
# TODO: puppetize clone of wikistats?
class statistics::wikistats {
    # Perl packages needed for wikistats
    package { [
        'libjson-xs-perl',
        'libtemplate-perl',
        'libnet-patricia-perl',
        'libregexp-assemble-perl',
    ]:
        ensure => 'installed',
    }
    # this cron uses pigz to unzip squid archive files in parallel
    package { 'pigz':
        ensure => 'installed',
    }

    # generates the new mobile pageviews report
    # and syncs the file PageViewsPerMonthAll.csv to stat1002
    cron { 'new mobile pageviews report':
        command  => '/bin/bash /a/wikistats_git/pageviews_reports/bin/stat1-cron-script.sh',
        user     => 'stats',
        monthday => 1,
        hour     => 7,
        minute   => 20,
    }
}

