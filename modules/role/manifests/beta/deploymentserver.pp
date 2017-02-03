# Role class for deployment servers in deployment-prep
#
# filtertags: labs-project-deployment-prep
class role::beta::deploymentserver {
    include beta::autoupdater
    include role::beta::mediawiki
}
