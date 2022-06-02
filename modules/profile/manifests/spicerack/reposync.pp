# @summary class to configure a server as a reposync receiver
# @param ensure ensureable parameter
# @param repos list of repos to configure
# @param remotes list of remote servers by default all cumin and netbox frontend hosts
class profile::spicerack::reposync (
    Wmflib::Ensure      $ensure  = lookup('profile::spicerack::reposync::ensure'),
    Array[String[1]]    $repos   = lookup('profile::spicerack::reposync::repos'),
    Array[Stdlib::Fqdn] $remotes = lookup('profile::spicerack::reposync::remotes'),
) {
    $_remotes = $remotes.empty ? {
        false   => $remotes,
        default => wmflib::role::hosts('cluster::management') + $facts['networking']['fqdn'] + wmflib::role::hosts('netbox::frontend'),
    }.sort.unique
    class {'reposync':
        ensure  => $ensure,
        repos   => $repos,
        remotes => $_remotes,
    }
}
