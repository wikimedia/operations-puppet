# Class package_builder::hooks
# A wrapper class for package::pbuilder_hooks. Mostly exists to make the
# addition of new distributions as easy as possible
class package_builder::hooks {
    # Wikimedia repos hooks
    # Note: sid does not have a wikimedia repo and will never do

    package_builder::pbuilder_hook { 'precise':
        distribution => 'precise',
        components   => 'main universe non-free thirdparty mariadb',
    }

    package_builder::pbuilder_hook { 'trusty':
        distribution => 'trusty',
        components   => 'main universe non-free thirdparty',
    }

    package_builder::pbuilder_hook { 'jessie':
        distribution => 'jessie',
        components   => 'main backports thirdparty',
    }
}
