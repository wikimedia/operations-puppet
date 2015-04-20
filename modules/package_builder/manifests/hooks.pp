# Class package_builder::hooks
# A wrapper class for package::pbuilder_hooks. Mostly exists to make the
# addition of new distributions as easy as possible
class package_builder::hooks(
    $basepath='/var/cache/pbuilder',
) {
    file { "${basepath}/hooks":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Note: sid does not have a wikimedia repo and will never do so no hook for
    # it for now
    package_builder::pbuilder_hook { 'precise':
        distribution => 'precise',
        components   => 'main universe non-free thirdparty mariadb',
        basepath     => $basepath,
    }

    package_builder::pbuilder_hook { 'trusty':
        distribution => 'trusty',
        components   => 'main universe non-free thirdparty',
        basepath     => $basepath,
    }

    package_builder::pbuilder_hook { 'jessie':
        distribution => 'jessie',
        components   => 'main backports thirdparty',
        basepath     => $basepath,
    }

    File["${basepath}/hooks"] -> Package_builder::Pbuilder_hook['precise']
    File["${basepath}/hooks"] -> Package_builder::Pbuilder_hook['trusty']
    File["${basepath}/hooks"] -> Package_builder::Pbuilder_hook['jessie']
}
