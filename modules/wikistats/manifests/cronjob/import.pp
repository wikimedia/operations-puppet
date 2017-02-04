# define a cronjob to import a wikistats table
define wikistats::cronjob::import() {

    $project = regsubst($name, '@.*', '\1')
    $weekday = regsubst($name, '.*@', '\1')

    cron { "cron-wikistats-import-${name}":
        ensure   => present,
        command  => "/usr/local/bin/wikistats/import_${project}_combined.sh > /var/log/wikistats/import_${project}.log 2>&1",
        user     => 'wikistatsuser',
        weekday => $weekday,
        hour     => '11',
        minute   => '11',
    }
}

