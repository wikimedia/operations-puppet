# SPDX-License-Identifier: Apache-2.0
# T320403
class profile::mediawiki::maintenance::campaignevents {
    if $::realm == 'labs' {
        # beta-meta
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-metawiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki metawiki',
            interval => '03:52'
        }
    } else {
        # group0: test.wikipedia.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-testwiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki testwiki',
            interval => '03:12'
        }

        # group0: office.mediawiki.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-officewiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki officewiki',
            interval => '03:32'
        }

        # group1: test2.wikipedia.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-test2wiki':
            command  => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki test2wiki',
            interval => '03:52'
        }
    }
}
