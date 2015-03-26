# == Class: puppetception
#
# Puppetception is an easy way to setup a labs project that
# uses a puppet repository that is *not* operations/puppet.git.
# This is for volunteer projects that want to use a puppetied
# environment but find it too hard to use operations/puppet or
# already have a puppet repository they want to reuse.
#
# The class sets up a git clone of the specified repository
# at the specified path, and auto pulls it to the specified
# branch on each run. Also provides a 'puppetception' command
# that when run will run puppet on the cloned repository.
#
# == Parameters
#
# [*git_url*]
#   The url to the git repository containing the puppet files
#   the project wants to use
#
# [*git_branch*]
#   The name of the git branch to pull.
#   Defaults to 'master'
#
# [*puppet_subdir*]
#   The name of the dir inside the repository where the puppet
#   files reside. This is useful if the remote repo contains
#   other files unrelated to puppet, and the puppet files are
#   in one particular subfolder.
#
# [*owner*]
#   The user who should own the cloned repository.
#   Defaults to 'root'
#
# [*group*]
#   The group that the cloned repository belongs to.
#   Defaults to 'root'
#

class puppetception(
    $git_url,
    $git_branch    = 'master',
    $puppet_subdir = '',
    $owner         = 'root',
    $group         = 'root',
) {
    include ::role::labs::lvm::srv

    $base_dir    = '/srv/puppetception'
    $install_dir = "${base_dir}/git"
    $puppet_dir  = "${install_dir}${puppet_subdir}"
    file { [$base_dir,
            $install_dir,
    ]:
        ensure  => directory,
        require => Mount['/srv'],
        owner   => $owner,
        group   => $group,
    }

    git::clone { $install_dir:
        ensure    => latest,
        directory => $install_dir,
        origin    => $git_url,
        require   => File[$install_dir],
        branch    => $git_branch,
        owner     => $owner,
        group     => $group,
    }

    file { '/sbin/puppetception':
        ensure  => present,
        content => template('puppetception/puppetception.erb'),
        mode    => '0700',
        owner   => 'root',
        group   => 'root',
    }
}
