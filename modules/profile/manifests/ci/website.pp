# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class profile::ci::website {

    # Needed at least for the jenkins-slave user
    require ::profile::ci::slave

    class { 'contint::website': }
}
