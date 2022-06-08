# SPDX-License-Identifier: Apache-2.0
# a timer (job) to dump wikistats tables as XML
define wikistats::job::xmldump(
    String $table,
    Integer $minute,
    String $db_pass,
    Wmflib::Ensure $ensure = 'present',
    String $db_user = 'wikistatsuser',
    String $db_name = 'wikistats',
    Stdlib::Unixpath $file_path = '/var/www/wikistats/xml',
    Stdlib::Unixpath $my_cnf = '/usr/lib/wikistats/.my.cnf',
){

    $query = $table ? {
        'wikipedias' => 'SELECT *,good/total AS ratio FROM wikipedias WHERE total IS NOT NULL ORDER BY good desc,total desc',
        default      => "SELECT *,good/total AS ratio FROM ${table} ORDER BY good desc,total desc",
    }

    $command = "/usr/bin/mysql --defaults-extra-file=${my_cnf} -X -u ${db_user} -e '${query}' ${db_name} > ${file_path}/${table}.xml 2>&1"

    systemd::timer::job { "wikistats-xmldump-${name}":
        ensure          => $ensure,
        user            => 'wikistatsuser',
        description     => "dump data from table ${name} in XML format",
        command         => $command,
        logging_enabled => true,
        logfile_basedir => '/var/log/wikistats/',
        logfile_name    => "xmldump-${name}.log",
        interval        => {'start' => 'OnCalendar', 'interval' => "*-*-* *:${minute}:00"},
    }

}
