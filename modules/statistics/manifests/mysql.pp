# == Class statistics::mysql
# Installs a mysql configuration file to connect to geowiki's
# research mysql instance
#
class statistics::mysql {
    require statistics::geowiki,
        passwords::mysql::research

    $geowiki_user      = $statistics::geowiki::geowiki_user
    $geowiki_base_path = $statistics::geowiki::geowiki_base_path

    $research_mysql_user = $passwords::mysql::research::user
    $research_mysql_pass = $passwords::mysql::research::pass

    $conf_file = "${geowiki_base_path}/.research.my.cnf"
    file { $conf_file:
        owner   => $geowiki_user,
        group   => $geowiki_user,
        mode    => '0400',
        content => "
[client]
user=${research_mysql_user}
password=${research_mysql_pass}
host=s1-analytics-slave.eqiad.wmnet
# make_limn_files.py relies on a set default-character-set.
# This setting was in erosen's original MySQL configuration files, and without
# it, make_files_limpy.py fails with UnicodeDecodeError when writing out the csv
# files
default-character-set=utf8
",
    }
}

