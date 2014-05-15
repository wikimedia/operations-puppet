# Definition: git::install
#
# Creates a git clone of a specified wikimedia project into a directory,
# and ensures that the correct tag is checked out.
#
# === Required parameters
#
# $+directory+:: Path to clone the repository into.
# $+git_tag+::       The tag to apply to the user.
#
# === Optional parameters
#
# $+ensure+:: _absent_ or _present_.  Defaults to _present_.
#             - _present_ (default) will keep the repository updated.
#             - _absent_ will ensure the directory is deleted.
# $+owner+:: Owner of $directory, default: _root_.  git commands will be run
#  by this user.
# $+group+:: Group owner of $directory, default: 'root'
# $+post_checkout+:: Post checkout hook script that can be used to perform
#  deploy tasks
#
# === Example usage
#
#   git::install { 'project/name/on/gerrit':
#       directory => '/some/path/here',
#       git_tag       => 'my-preferred-tag',
#       post_checkout  => 'puppet://files/some/script/that/should/run/post/checkout'
#   }
#
#
#
define git::install(
    $directory,
    $git_tag,
    $ensure='present',
    $post_checkout=undef,
    $owner='root',
    $group='root',
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
                require => Git::Clone[$title] #TODO: check me!
            }
        }


        exec {"git_update_${title}":
            command => 'git remote update',
            cwd     => $directory,
            user    => $owner,
            unless  => "git tag --list | grep ${git_tag}",
            require => Git::Clone[$title],
        }

        exec {"git_checkout_${title}":
            command => "git checkout tags/${git_tag}",
            cwd     => $directory,
            user    => $owner,
            require => Exec["git_update_${title}"]
        }
    }
}
