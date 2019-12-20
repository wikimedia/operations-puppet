# Definition: netbox::autogit
#
# Creates a bare Git repository ready to be used locally to the machine in question.
# Adds to it the remotes of the other hosts to allow git pull between them.
# Intended for automation to distribute their results via git repository.
#
# Actions:
#   Create bare git repository
#   Set git remotes
#   Add post-update hook so that it will work with an HTTP server.
#
# Parameters:
#   $title = the name of the git repository (which will be "title.git" in the end)
#   $owner = the owner of the repository (default: netbox)
#   $group = the group of the repository (default: www-data)
#   $mode = the mode of the repository (default: 2755)
#   $repo_path = The parent path of the repository (default: /srv/automation)
#   $frontends = list of hosts serving as a frontend to this repo
#

define netbox::autogit (
    String $owner = 'netbox',
    String $group = 'www-data',
    String $mode = '2755',
    Stdlib::Unixpath $repo_path = '/srv/automation',
    Array[Stdlib::Fqdn] $frontends = [],
) {
    $git='/usr/bin/git --bare init'
    $repofullpath = "${repo_path}/${title}.git"
    $creates="${repofullpath}/config"

    file { [$repo_path, $repofullpath]:
        ensure => directory,
        owner  => $owner,
        group  => $group,
        mode   => $mode,
    }

    # Create a bare repository with git.
    exec { "initialize automation git repository ${title}":
        command => $git,
        creates => $creates,
        user    => $owner,
        group   => $group,
        cwd     => $repofullpath,
        require => File[$repofullpath],
    }

    # Deploy a post-update script so we can serve this via http.
    file { "${repofullpath}/hooks/post-update":
        source => 'puppet:///modules/netbox/autogit-post-update.sh',
        owner  => $owner,
        group  => $group,
        mode   => '0550',
    }

    file { "${repofullpath}/config":
        owner   => $owner,
        group   => $group,
        mode    => '0640',
        content => template('netbox/autogit-config.erb'),
    }
}
