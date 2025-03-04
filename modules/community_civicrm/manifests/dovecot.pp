# SPDX-License-Identifier: Apache-2.0
# @summary the dovecot server setup for the community_civicrm site
#
# @param imap_address ip address for imap server to listen on
# @param imap_port port number for imap service
# @param mail_location default mailbox format and location for dovecot
#
class community_civicrm::dovecot (
    Stdlib::Host $imap_address = '127.0.0.1',
    Stdlib::Port $imap_port = 143,
    String $mail_location = 'maildir:~/Maildir',

){

    ensure_packages('dovecot-imapd')

    service { 'dovecot':
        ensure    => 'running',
        require   => Package['dovecot-imapd'],
        subscribe => File[
            '/etc/dovecot/dovecot.conf',
        ],
        enable    => true,
    }

    file { '/etc/dovecot/dovecot.conf':
        ensure  => 'file',
        mode    => '0444',
        require => Package['dovecot-imapd'],
        content => template('community_civicrm/dovecot/dovecot.conf.erb'),
    }

    file { '/etc/dovecot/passwd':
        ensure  => 'file',
        group   => 'dovecot',
        mode    => '0440',
        require => Package['dovecot-imapd'],
        content => secret('community_civicrm/dovecot_passwd'),
    }

}
