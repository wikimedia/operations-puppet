# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class role::ci::website {

    system::role { 'role::ci::website': description => 'CI Websites' }

    # Needed at least for the jenkins-slave user
    require ::role::ci::slave

    include role::zuul::configuration

    class { 'contint::website':
        zuul_git_dir => $role::zuul::configuration::zuul_git_dir,
    }
}
