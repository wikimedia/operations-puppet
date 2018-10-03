# === Class wdqs::autodeploy
#
# Wikidata Query Service Auto deployment.
#
class wdqs::autodeploy(
    $package_dir,
    String $log_dir = '/var/log/wdqs',
    String $username = 'deploy-service'
) {

    $wdqs_autodeployment_log = "${log_dir}/wdqs_autodeployment.log"

    file { '/usr/local/bin/wdqs-autodeploy':
        ensure => present,
        source => 'puppet:///modules/wdqs/cron/wdqs-autodeploy.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'wdqs-autodeploy':
        ensure  => present,
        command => "/usr/local/bin/wdqs-autodeploy ${package_dir} >> ${$wdqs_autodeployment_log} 2>&1",
        user    => $username,
        hour    => [5, 11, 17, 23]
    }

    logrotate::rule { 'wdqs_autodeployment_log':
        ensure       => present,
        file_glob    => $wdqs_autodeployment_log,
        frequency    => 'daily',
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 30,
        compress     => true,
    }
}