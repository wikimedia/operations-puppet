# == Class role::ci::slave::labs::light
#
# Transient role that setup a slave labs for Jessie.  Regular slaves include
# mediawiki::packages and over cmaterials which are not yet ready on Jessie
# (tracking task is https://phabricator.wikimedia.org/T94836).
#
# Let us migrate some jobs to Jessie since production is moving toward it.
#
class role::ci::slave::labs::light {

    requires_realm('labs')

    system::role { 'role::ci::slave::labs::light':
        description => 'CI *LIGHT* Jenkins slave on labs' }

    # Trebuchet replacement on labs
    include contint::slave_scripts
    include role::ci::slave::labs::common

    include contint::packages::apt
    include contint::packages::ops
    include contint::packages::python

}

