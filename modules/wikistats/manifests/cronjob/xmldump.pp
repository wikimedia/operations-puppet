# define a cronjob to dump xml tables
define wikistats::cronjob::xmldump(
    $table,
    $minute,
    $db_pass,
    $db_user = 'wikistatsuser',
    $db_name = 'wikistats',
    $file_path = '/var/www/wikistats/xml',
){

    $query = $table ? {
        'wikipedias' => 'SELECT *,good/total AS ratio FROM wikipedias WHERE lang NOT LIKE \"%articles%\" ORDER BY good desc,total desc',
        default      => "SELECT *,good/total AS ratio FROM ${table} ORDER BY good desc,total desc",
    }

    $command = "mysql -X -u ${db_user} -p${db_pass} -e '${query}' ${db_name} > ${file_path}/${table}.xml"

    file { $file_path:
        ensure => directory,
        owner  => 'wikistatsuser',
        group  => 'wwww-data',
        mode   => '0644',
    }

    cron { "cron-wikistats-xmldump-${name}":
        ensure  => present,
        command => $command,
        user    => 'wikistatsuser',
        minute  => $minute,
    }
}

