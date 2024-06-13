# SPDX-License-Identifier: Apache-2.0
# @summary
#     Configures the VRTS alias script generator, which generates aliases to ensure
#     VRTS recipients are forwarded to VRTS
# @param gmail_host
#     Gmail server to query for conflicting VRTS accounts
# @param aliases_file
#     Destination path for generated aliases
# @param aliases_format
#     MTA Server format of generated aliases
# @param aliases_folder
#     MTA Server folder of existing aliases
# @param mysql_dbname
#     MySQL database name
# @param mysql_password
#     MySQL database password
# @param mysql_host
#     MySQL server Hostname
# @param mysql_user
#     MySQL database user
# @param wikimedia_domains
#     Wikimedia domains for which to generate VRTS aliases
class profile::mail::vrts (
    Stdlib::Host            $gmail_host        = lookup('profile::mail::vrts::gmail_host'),
    Stdlib::Absolutepath    $aliases_file      = lookup('profile::mail::vrts::aliases_file'),
    Enum['exim', 'postfix'] $aliases_format    = lookup('profile::mail::vrts::aliases_format'),
    Stdlib::Absolutepath    $aliases_folder    = lookup('profile::mail::vrts::aliases_folder'),
    Stdlib::Host            $mysql_dbname      = lookup('profile::mail::vrts::mysql_dbname'),
    Sensitive[String[1]]    $mysql_password    = lookup('profile::mail::vrts::mysql_password'),
    Stdlib::Host            $mysql_host        = lookup('profile::mail::vrts::mysql_host'),
    String[1]               $mysql_user        = lookup('profile::mail::vrts::mysql_user'),
    Array[Stdlib::Host]     $wikimedia_domains = lookup('profile::mail::vrts::wikimedia_domains'),
    String[1]               $next_hop          = lookup('profile::mail::vrts::next_hop'),
){
    file { '/etc/vrts':
        ensure => directory,
        mode   => '0555',
    }

    $wikimedia_domains_path = '/etc/vrts/wikimedia_domains'
    file { $wikimedia_domains_path:
        ensure  => present,
        mode    => '0444',
        content => $wikimedia_domains.reduce('') |$memo, $v| {
            "${memo}${v}\n"
        },
    }

    $vrts_aliases_conf = '/etc/vrts/vrts.conf'
    file { $vrts_aliases_conf:
        ensure  => present,
        mode    => '0440',
        owner   => 'postfix',
        group   => 'postfix',
        content => epp('profile/mail/mx/vrts.conf.epp', {
            gmail_smtp_server      => $gmail_host,
            vrts_aliases_file      => $aliases_file,
            vrts_aliases_format    => $aliases_format,
            vrts_aliases_folder    => $aliases_folder,
            vrts_mysql_dbname      => $mysql_dbname,
            vrts_mysql_password    => $mysql_password,
            vrts_mysql_server      => $mysql_host,
            vrts_mysql_user        => $mysql_user,
            wikimedia_domains_path => $wikimedia_domains_path,
            next_hop               => $next_hop,
        })
    }

    ensure_packages(['python3-pymysql'])
    file {'/usr/local/bin/vrts_aliases':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/mail/vrts_aliases.py',
    }

    systemd::timer::job {'generate_vrts_aliases':
        ensure            => 'present',
        description       => "Generate VRTS aliases file for ${aliases_format}",
        command           => "/usr/local/bin/vrts_aliases --config ${vrts_aliases_conf}",
        user              => 'postfix',
        interval          => {'start' => 'OnUnitInactiveSec', 'interval' => '1h'},
        timeout_start_sec => 1800,
    }
}
