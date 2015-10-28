# Copied from nagios::ganglia::monitor::enwiki
# Will run on terbium to use the local MediaWiki install so that we can use
# maintenance scripts recycling DB connections and taking a few secs, not mins
class mediawiki::maintenance::jobqueue_monitor {

    cron { 'all_jobqueue_length':
        ensure  => present,
        command => "/usr/bin/gmetric --name='Global JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --value=$(/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --totalonly | grep -oE '[0-9]+') > /dev/null 2>&1",
        user    => 'mwdeploy',
    }

    # duplicating the above job to experiment with gmetric's host spoofing so
    # as to gather these metrics in a fake host called "www.wikimedia.org"
    cron { 'all_jobqueue_length_spoofed':
        ensure  => present,
        command => "/usr/bin/gmetric --name='Global JobQueue length' --type=int32 --conf=/etc/ganglia/gmond.conf --spoof 'www.wikimedia.org:www.wikimedia.org' --value=$(/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --totalonly | grep -oE '[0-9]+') > /dev/null 2>&1",
        user    => 'mwdeploy',
    }
}

