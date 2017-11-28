# Role class for deployment servers in deployment-prep
#
# filtertags: labs-project-deployment-prep
class role::beta::deploymentserver {
    include profile::beta::autoupdater
    include role::beta::mediawiki
}
