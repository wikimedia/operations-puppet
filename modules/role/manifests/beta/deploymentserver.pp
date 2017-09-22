# Role class for deployment servers in deployment-prep
#
# filtertags: labs-project-deployment-prep
class role::beta::deploymentserver {
    class { '::beta::autoupdater':
        user => hiera( 'jenkins_agent_username' ),
    }
    include role::beta::mediawiki
}
