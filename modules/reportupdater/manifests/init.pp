# == Class reportupdater
#
# Sets up repositories and rsync for using reportupdater.
# See: https://wikitech.wikimedia.org/wiki/Analytics/Reportupdater
#
# == Parameters
#   $user           - string. User for cloning repositories and folder permits.
#   $source_path    - string. Base path where to put reportupdater's repository.
#   $public_path    - string. [optional] Path to be rsync'd to a public node.
#   $rsync_to       - string. [optional] If defined, all what is in the public
#                     path will be rsync'd to $rsync_to.
#
class reportupdater(
    $user,
    $source_path,
    $public_path = "${source_path}/reportupdater-output",
    $rsync_to    = undef,
) {

    # Ensure reportupdater is cloned and latest version.
    if !defined(Git::Clone['analytics/reportupdater']) {
        git::clone { 'analytics/reportupdater':
            ensure    => 'latest',
            directory => "${source_path}/reportupdater",
            origin    => 'https://gerrit.wikimedia.org/r/p/analytics/reportupdater.git',
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # If specified, rsync anything generated in $public_path to $rsync_to.
    if $rsync_to != undef {
        cron { 'rsync_reportupdater_output':
            command => "/usr/bin/rsync -rt ${public_path}/* ${rsync_to}",
            user    => $user,
            minute  => 15,
        }
    }
}
