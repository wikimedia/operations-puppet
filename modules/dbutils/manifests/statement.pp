# SPDX-License-Identifier: Apache-2.0
define dbutils::statement (
    String[1]           $statement,
    String[1]           $unless,
    Optional[String[1]] $unless_grep_match = undef,
) {
    $exec_user = 'root'
    $exec_bin = '/usr/bin/mysql'
    $exec_args = "--user=${exec_user} --batch --silent -e"
    $exec_timeout = '30'

    if $unless_grep_match {
        $match = $unless_grep_match
    } else {
        $match = $statement
    }

    exec { "db-statement-${title}":
        command => "${exec_bin} ${exec_args} \"${statement};\"",
        unless  => "${exec_bin} ${exec_args} \"${unless};\" | grep -q \"${match}\"",
        user    => $exec_user,
        timeout => $exec_timeout,
    }
}
