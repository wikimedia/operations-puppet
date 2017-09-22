# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class role::ci::website {

    system::role { 'ci::website': description => 'CI Websites' }

    # Needed at least for the Jenkins agent username
    require ::role::ci::slave

    class { 'contint::website':
        user => hiera('jenkins_agent_username'),
    }
}
