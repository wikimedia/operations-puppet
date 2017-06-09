# define a cronjob to dump xml tables
# usage: <project prefix>@<hour>
define wikistats::cronjob::xmldump() {

    $project = regsubst($name, '@.*', '\1')
    $hour    = regsubst($name, '.*@', '\1')

    cron { "cron-wikistats-xmldump-${name}":
        ensure  => present,
        command => "",
        user    => 'wikistatsuser',
        hour    => $hour,
        minute  => 0,
    }
}

