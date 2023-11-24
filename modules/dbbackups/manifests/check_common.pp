# SPDX-License-Identifier: Apache-2.0
# Common setup for the database backups check:
# package installation and config file
## Parameters:
# * config_file: the path of the file that will be created, containing
#                the mysql connection options
# * valid_sections_file: relative puppet path of the file containing valid
#   sections to check (to avoid typos and missconfigurations)
# * db_user: MySQL username used to connect to the database backup metadata
#            (it requires SELECT permisions)
# * db_host: MySQL fqdn of the host where the backup metadata database lives
# * db_password: MySQL password of the backup metadata database
# * db_database: Schema name of the backup metadata database

class dbbackups::check_common (
    Stdlib::Unixpath $config_file,
    String $valid_sections_file,
    String $db_user,
    String $db_host,
    String $db_password,
    String $db_database,
){
    ensure_packages('wmfbackups-check')

    file { '/etc/wmfbackups/valid_sections.txt':
        ensure  => present,
        source  => $valid_sections_file,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        require => [ Package['wmfbackups-check'] ],
    }

    file { $config_file:
        ensure  => present,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        content => template('dbbackups/backups_check.ini.erb')
    }
}
