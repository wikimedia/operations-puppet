# SPDX-License-Identifier: Apache-2.0
# phabricator - informational emails for admins
#
class profile::phabricator::logmail (
    Boolean                     $logmail            = lookup('phabricator_logmail',
                                                      { 'default_value' => false }),
    String                      $deploy_target      = lookup('phabricator_deploy_target',
                                                      { 'default_value' => 'phabricator/deployment'}),
    String                      $mysql_slave        = lookup('phabricator::mysql::slave',
                                                      { 'default_value' => 'localhost' }),
    String                      $mysql_slave_port   = lookup('phabricator::mysql::slave::port',
                                                      { 'default_value' => '3323' }),
    String                      $sndr_address       = lookup('profile::phabricator::logmail::sndr_adddress',
                                                      { 'default_value' => 'phabricator@wikimedia.org' }),
){

    # logmail must be explictly enabled in Hiera with 'phabricator_logmail: true'
    # to avoid duplicate mails from labs and standby (T173297)
    $logmail_ensure = $logmail ? {
        true    => 'present',
        default => 'absent',
    }

    # community metrics mail (T81784, T1003)
    phabricator::logmail {'community_metrics':
        ensure           => $logmail_ensure,
        rcpt_address     => 'wikitech-l@lists.wikimedia.org',
        sndr_address     => $sndr_address,
        monthday         => 1,
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_maniphest',
    }

    # project changes mail (T85183)
    phabricator::logmail {'project_changes':
        ensure           => $logmail_ensure,
        rcpt_address     => [ 'phabricator-reports@lists.wikimedia.org' ],
        sndr_address     => $sndr_address,
        weekday          => 'Monday',
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_project',
    }

    # multi-factor auth mail (T299403)
    phabricator::logmail {'mfa_check':
        ensure           => $logmail_ensure,
        rcpt_address     => [ 'aklapper@wikimedia.org' ],
        sndr_address     => $sndr_address,
        weekday          => 'Wednesday',
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_user',
    }

    # yearly metrics mail (T337388)
    phabricator::logmail {'yearly_metrics':
        ensure           => $logmail_ensure,
        rcpt_address     => [ 'aklapper@wikimedia.org', 'releng@lists.wikimedia.org' ],
        sndr_address     => $sndr_address,
        month            => 1,
        monthday         => 1,
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_maniphest',
    }

    # quarterly metrics mail (T337387)
    phabricator::logmail {'quarterly_metrics':
        ensure           => $logmail_ensure,
        rcpt_address     => [ 'dtankersley@wikimedia.org', 'aklapper@wikimedia.org' ],
        sndr_address     => $sndr_address,
        month            => '01,04,07,10',
        monthday         => 1,
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_maniphest',
    }

    # quarterly wmf qls mail (T362804)
    phabricator::logmail {'quarterly_wmf_qls':
        ensure           => $logmail_ensure,
        rcpt_address     => [ 'abittaker@wikimedia.org', 'aramirez@wikimedia.org', 'aklapper@wikimedia.org' ],
        sndr_address     => 'aklapper@wikimedia.org',
        month            => '01,04,07,10',
        monthday         => 1,
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_maniphest',
    }

    # weekly tech news mail (T368460, T373952)
    phabricator::logmail {'tech_news_weekly_stats':
        ensure           => $logmail_ensure,
        rcpt_address     => [ 'nwilson@wikimedia.org', 'jjonsson@wikimedia.org', 'bevellin@wikimedia.org', 'uzoma@wikimedia.org'],
        sndr_address     => 'aklapper@wikimedia.org',
        weekday          => 'Thursday',
        hour             => 12,
        require          => Package[$deploy_target],
        mysql_slave      => $mysql_slave,
        mysql_slave_port => $mysql_slave_port,
        mysql_db_name    => 'phabricator_maniphest',
    }
}
