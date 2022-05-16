# SPDX-License-Identifier: Apache-2.0
# Common setup for the database backups check:
# package installation and config file
class dbbackups::check_common (
    String $valid_sections_file,
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

}
