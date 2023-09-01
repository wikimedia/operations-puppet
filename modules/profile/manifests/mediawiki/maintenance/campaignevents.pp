# SPDX-License-Identifier: Apache-2.0
# T320403
class profile::mediawiki::maintenance::campaignevents {
    # group0: meta.wikimedia.org both in beta and production
    profile::mediawiki::periodic_job { 'campaignevents-updateutcts-metawiki':
        command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki metawiki',
        interval => '02:52'
    }
    profile::mediawiki::periodic_job { 'campaignevents-aggregateparticipantanswers-metawiki':
        command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki metawiki',
        interval => '00/03:00',
        splay    => 300,
    }

    unless $::realm == 'labs' {
        # group0: test.wikipedia.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-testwiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki testwiki',
            interval => '03:12'
        }
        profile::mediawiki::periodic_job { 'campaignevents-aggregateparticipantanswers-testwiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki testwiki',
            interval => '00/03:00',
            splay    => 300,
        }

        # group0: office.mediawiki.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-officewiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki officewiki',
            interval => '03:32'
        }
        profile::mediawiki::periodic_job { 'campaignevents-aggregateparticipantanswers-officewiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki officewiki',
            interval => '00/03:00',
            splay    => 300,
        }

        # group1: test2.wikipedia.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-test2wiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki test2wiki',
            interval => '03:52'
        }
        profile::mediawiki::periodic_job { 'campaignevents-aggregateparticipantanswers-test2wiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki test2wiki',
            interval => '00/03:00',
            splay    => 300,
        }
    }
}
