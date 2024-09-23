# SPDX-License-Identifier: Apache-2.0
# @summary This class handles creating a repository and replicating it to other servers.
#
# @param title The name of the repository. It will be installed under /srv/git.
#
# @param servers List of servers that host the repository. The first server in
#                the list is the controller, which is the server that the
#                repository is cloned from. If the list is empty, or just the
#                current server is listed, this is assumed to be the only server
#                hosting the repository at the moment, and the repository is
#                initialized.
#
# @param user The user that owns the repository.
#
# @param user_homedir The home directory of the user that owns the repository.
#
# @param ssh_pubkey The public key to add to the authorized_keys file.
#
# @param ssh_privkey The private key to use for the git clone.
#
# @param mail_changes Whether to send an email when a change is made to the
#                     repository. Default: false.
#
# @param mailto The email address to send the email to. Default:
#               ops@wikimedia.org
#
define git::replicated_local_repo (
    Array[Stdlib::Fqdn] $servers,
    String $user,
    String $user_homedir,
    String $ssh_pubkey,
    Sensitive[String] $ssh_privkey,
    Boolean $mail_changes = false,
    String $mailto = 'ops@wikimedia.org',
) {
    $repo_path = "/srv/git/${title}"
    $safe_title = regsubst($title, '[^a-zA-Z0-9]', '_', 'G')
    ## ssh setup ##

    file { "${user_homedir}/.ssh":
        ensure => directory,
        owner  => $user,
        group  => $user,
        mode   => '0700',
    }

    $privkey_path = "${user_homedir}/.ssh/id_${safe_title}"
    $git_ssh_wrapper = "${user_homedir}/.ssh/ssh_wrapper_${safe_title}"
    $authorized_keys = "${user_homedir}/.ssh/authorized_keys"

    # We want to be able to connect to other servers
    file { $privkey_path:
        ensure  => file,
        content => $ssh_privkey,
        owner   => $user,
        group   => $user,
        mode    => '0600',
    }

    # And to allow other servers to connect to us
    if (!defined(File[$authorized_keys])) {
        file { $authorized_keys:
            ensure => file,
            owner  => $user,
            group  => $user,
            mode   => '0600',
        }
    }
    file_line { "authorized_keys ${safe_title}" :
        ensure  => 'present',
        path    => $authorized_keys,
        line    => $ssh_pubkey,
        require => File[$authorized_keys],
    }

    file { $git_ssh_wrapper:
        ensure  => file,
        content => "#!/bin/sh\n/usr/bin/ssh -i '${privkey_path}' \"$@\"",
        owner   => $user,
        group   => $user,
        mode    => '0550',
    }

    ## git setup ##

    # If we have more than just this server, clone from another server and  install the git commit hook.
    # Otherwise, just initialize the repository.
    if ($servers != [] and $servers != [$facts['networking']['fqdn']]) {
        $controller = $servers[0]
        $git_command = "GIT_SSH=${git_ssh_wrapper} /usr/bin/git clone 'ssh://${user}@${controller}:${repo_path}' '${repo_path}'"
        $hook_ensure = file
    } else {
        $git_command = "/usr/bin/git -C '${repo_path}' init"
        $hook_ensure = absent
        # TODO: add a README with a "What not to do" section?
    }

    $create = "git init ${safe_title}"

    exec { $create:
        command => "/usr/bin/mkdir -p '${repo_path}' && ${git_command} && chown -R '${user}:${user}' '${repo_path}'",
        creates => "${repo_path}/.git",
    }

    file { "${repo_path}/.git/hooks/postcommit":
        ensure  => $hook_ensure,
        content => template('git/replicated_local_postcommit.sh.erb'),
        owner   => $user,
        group   => $user,
        require => Exec[$create],
    }
}
