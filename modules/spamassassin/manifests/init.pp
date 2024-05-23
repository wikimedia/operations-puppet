# SPDX-License-Identifier: Apache-2.0
# == Class: spamassassin
#
# This class installs & manages SpamAssassin, http://spamassassin.apache.org/
#
# == Parameters
#
# [*required_score*]
#   The minimum required score to mark a message as spam. Defaults to 5.0
#
# [*max_children*]
#   Number of spamd workers to fork. Defaults to 8.
#
# [*nicelevel*]
#  Nice level to run spamd as. Defaults to 10.
#
# [*use_bayes*]
#  Use Bayesian classifier. Defaults to 1.
#
# [*bayes_auto_learn*]
#  Bayesian classifier auto-learning. Defaults to 1.
#
# [*short_report_template*]
#  Short-format report template. Defaults to false.
#
# [*trusted_networks*]
#  Networks for which to trust Received headers from. Defaults to [].
#
# [*spamd_user*]
#  The user to run spamd as. Defaults to "debian-spamd", which is
#  created if non-existent.
#
# [*spamd_group*]
#  The group to run spamd as. Defaults to "debian-spamd", which is
#  created if non-existent.
#
# [*custom_scores*]
#  Provide custom scores to existing tests. Hash of score => value, defaults
#  to an empty hash.
#
# [*debug_logging*]
#  Enable debug logging. Defaults to none. Example: "--debug spf"
#  See: http://wiki.apache.org/spamassassin/DebugChannels
#
# [*proxy*]
#  Enable proxy for sa-update. Useful for hosts without direct internet acces.
#  Defaults to undef
#
# [*monitoring_ensure*]
#  Determines whether to include the nrpe monitor for spamd. Defaults to 'present'
#
class spamassassin(
    $required_score = '5.0',
    $max_children = 8,
    $nicelevel = 10,
    $use_bayes = 1,
    $bayes_auto_learn = 1,
    $short_report_template = false,
    $trusted_networks = [],
    $spamd_user  = 'debian-spamd',
    $spamd_group = 'debian-spamd',
    $custom_scores = {},
    $debug_logging = '',
    $proxy = undef,
    $monitoring_ensure = 'present',
) {
    if debian::codename::ge('bookworm') {
        $sa_daemon='spamd'
    } else {
        $sa_daemon='spamassassin'
    }

    ensure_packages([$sa_daemon, 'libmail-spf-perl', 'libmail-dkim-perl'])

    file { '/etc/spamassassin/local.cf':
        content => template('spamassassin/local.cf'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package[$sa_daemon],
    }

    file { '/etc/default/spamassassin':
        content => template('spamassassin/spamassassin.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package[$sa_daemon],
    }

    service { $sa_daemon:
        ensure    => running,
        require   => [
            File['/etc/default/spamassassin'],
            File['/etc/spamassassin/local.cf'],
            Package[$sa_daemon],
        ],
        subscribe => [
            File['/etc/default/spamassassin'],
            File['/etc/spamassassin/local.cf']
        ],
    }

    nrpe::monitor_service { 'spamd':
        ensure       => $monitoring_ensure,
        description  => 'spamassassin',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:20 -c 1:40 -a spamd',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Mail#SpamAssassin',
    }

    # If we need a proxy to reach the internet, we need a slightly modified
    # script updating spamassassin.
    if $proxy {
        file { '/etc/cron.daily/spamassassin':
            ensure  => absent,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('spamassassin/sa-update-cron.erb'),
        }

        file { '/usr/local/sbin/spamassassin_updates':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => template('spamassassin/sa-update-cron.erb'),
        }

        systemd::timer::job { 'spamassassin_updates':
            ensure        => present,
            description   => 'Spamassassin definitions update',
            user          => 'root',
            command       => '/usr/local/sbin/spamassassin_updates',
            interval      => {'start' => 'OnCalendar', 'interval' => '*-*-* 09:17:00'},
            ignore_errors => true,
        }
    }
}
