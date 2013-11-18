# wikimetrics.pp - role class defining the wikimetrics website

# == Class role::wikimetrics
# Wikimetrics is the mediawiki metric reporting website
class role::wikimetrics {

    # Include Wikimetrics repository deployment target.
    deployment::target { 'analytics-wikimetrics': }
    # wikimetrics repository is deployed via git deploy into here.
    # You must deploy this yourself, puppet will not do it for you.
    $path = '/srv/deployment/analytics/wikimetrics'
}
