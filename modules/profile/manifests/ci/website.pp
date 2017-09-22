# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class profile::ci::website {
    class { 'contint::website':
        user => hiera('jenkins_agent_username'),
    }
}
