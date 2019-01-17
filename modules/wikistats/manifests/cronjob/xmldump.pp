# define a cronjob to dump xml tables
define wikistats::cronjob::xmldump(
    String $table,
    Integer $minute,
    String $db_pass,
    String $db_user = 'wikistatsuser',
    String $db_name = 'wikistats',
    Stdlib::Unixpath $file_path = '/var/www/wikistats/xml',
){

    $query = $table ? {
        'wikipedias' => 'SELECT *,good/total AS ratio FROM wikipedias WHERE lang NOT LIKE "%articles%" ORDER BY good desc,total desc',
        default      => "SELECT *,good/total AS ratio FROM ${table} ORDER BY good desc,total desc",
    }

    $command = "mysql --defaults-extra-file=/usr/lib/wikistats/.my.cnf -X -u ${db_user} -e '${query}' ${db_name} > ${file_path}/${table}.xml 2>&1"

    cron { "cron-wikistats-xmldump-${name}":
        ensure  => present,
        command => $command,
        user    => 'wikistatsuser',
        minute  => $minute,
    }
}

