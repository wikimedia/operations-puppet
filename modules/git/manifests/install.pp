# Definition: git::install
#
# Creates a git clone of a specified wikimedia project into a directory,
# and ensures that the correct tag is checked out.
#
# === Required parameters
#
# [*directory*]
#   Path to clone the repository into.
#
# [*git_tag*]
#   The tag to checkout in the repository
#
# === Optional parameters
#
# [*ensure*]
#   _absent_ or _present_
#     * _present_ (default) will keep the repository updated.
#     * _absent_ will ensure the directory is deleted.
#
# [*owner*]
#   Owner of $directory.
#
#  Note:
#    git commands will be run by this user.
#
# [*group*]
#   Group owner of $directory
#
# [*post_checkout*]
#   Post checkout hook script that can be used to perform deploy tasks
#
# [*lock_file*]
#   Specifies a file on disk whose presence will cause the repository to
#   hold at the last specified tag
#
#   NOTE: If the lock file exists and the tag on disk does not match
#         the current tag in Puppet a notice will be thrown.
#
#         Example:
#           <path_to_repo> is out of sync with upstream tag <tag_in_puppet>
#
# === Example usage
#
#   git::install { 'project/name/on/gerrit':
#       directory => '/some/path/here',
#       git_tag       => 'my-preferred-tag',
#       post_checkout  => 'puppet://files/some/script/that/should/run/post/checkout'
#   }
#

define git::install(
    $directory,
    $git_tag,
    $lock_file='',
    $post_checkout=undef,
    $owner='root',
    $group='root',
    $ensure='present',
    )
{
    # Git clone runs once, then we perform a "forward-to-tag" operation
    git::clone{$title:
        ensure    => $ensure,
        directory => $directory,
        owner     => $owner,
        group     => $group,
        mode      => '0444',
    }

    if $ensure == 'present' {

        if $post_checkout != undef {
            file {"callback-hook-${title}":
                ensure  => 'present',
                path    => "${directory}/.git/hooks/post-checkout",
                mode    => '0554',
                source  => $post_checkout,
                owner   => $owner,
                group   => $group,
                require => Git::Clone[$title]
            }
        }

        if ($lock_file) {

            exec {"${title}_confirm_tag_version":
                command   => "/bin/true",
                cwd       => $directory,
                user      => $owner,
                unless    => "git diff HEAD..${git_tag} --exit-code",
                path      => '/usr/bin/:bin',
                logoutput => false,
                notify    => Exec["${title}_alert_for_out_of_sync"],
            }

            exec { "${title}_alert_for_out_of_sync":
                command => "/bin/echo ${directory} is out of sync with upstream tag ${git_tag}",
                logoutput => true,
                before  => Exec["git_update_${title}"],
                refreshonly => true,
            }
        }

        exec {"git_update_${title}":
            command => '/usr/bin/git remote update && git fetch --tags',
            creates => $lock_file,
            cwd     => $directory,
            user    => $owner,
            unless  => "git clean -df & git checkout . && git diff HEAD..${git_tag} --exit-code",
            path    => '/usr/bin/',
            require => Git::Clone[$title],
            notify  => Exec["git_checkout_${title}"],
        }

        exec {"git_checkout_${title}":
            command     => "git checkout tags/${git_tag}",
            cwd         => $directory,
            user        => $owner,
            path        => '/usr/bin/',
            refreshonly => true
        }
    }
}
