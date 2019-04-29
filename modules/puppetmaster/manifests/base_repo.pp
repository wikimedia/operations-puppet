# Class puppetmaster::base_repo
#
# Checkout the base git repo for operations/puppet
#
class puppetmaster::base_repo (
    $gitdir='/var/lib/git',
    $owner='root',
    $group='root',
    $gitowner='root',
) {

    file { [$gitdir, "${gitdir}/operations"]:
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => '0755',
    }
    git::clone { 'operations/puppet':
        directory          => "${gitdir}/operations/puppet",
        branch             => 'production',
        origin             => 'https://gerrit.wikimedia.org/r/operations/puppet',
        recurse_submodules => true,
        owner              => $gitowner,
        group              => $gitowner,
        require            => File["${gitdir}/operations"],
    }
}
