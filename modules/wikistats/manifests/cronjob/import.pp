 # define a cronjob to import a wikistats table
define wikistats::cronjob::import(
    Integer $weekday,
    Wmflib::Ensure $ensure = 'present',
){
    $project = $name

    cron { "cron-wikistats-import-${name}":
        ensure  => $ensure,
        command => "/usr/local/bin/wikistats/import_${project}.sh > /var/log/wikistats/import_${project}.log 2>&1",
        user    => 'wikistatsuser',
        weekday => $weekday,
        hour    => '11',
        minute  => '11',
    }
}
