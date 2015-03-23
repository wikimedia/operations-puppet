# define a cronjob to update a wikistats table
# usage: <project prefix>@<hour>
define wikistats::cronjob() {

    $project = regsubst($name, '@.*', '\1')
    $hour    = regsubst($name, '.*@', '\1')

    cron { "cron-wikistats-update-${name}":
        ensure  => present,
        command => "/usr/bin/php /usr/lib/wikistats/update.php ${project} > /var/log/wikistats/update_${name}.log 2>&1",
        user    => 'wikistatsuser',
        hour    => $hour,
        minute  => 0,
    }
}

