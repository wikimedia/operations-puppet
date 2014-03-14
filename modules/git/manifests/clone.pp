# Definition: git::clone
#
# Creates a git clone of a specified origin into a top level directory.
#
# === Required parameters
#
# $+directory+:: path to clone the repository into.
#
# === Optional parameters
#
# $+origin+:: If this is not specified, the the $title repository will be
#             checked out from gerrit using a default gerrit url.
#             If you set this, please specify the full repository url.
# $+branch+:: Branch you would like to check out.
# $+ensure+:: _absent_, _present_, or _latest_.  Defaults to _present_.
#             - _present_ (default) will just clone once.
#             - _latest_ will execute a git pull if there are any changes.
#             - _absent_ will ensure the directory is deleted.
# $+owner+:: Owner of $directory, default: _root_.  git commands will be run
#  by this user.
# $+group+:: Group owner of $directory, default: 'root'
# $+recurse_submodules:: If true, git
# $+mode+:: Permission mode of $directory, default: 2755 if shared, 0755 otherwise
# $+ssh+:: SSH command/wrapper to use when checking out, default: ''
# $+timeout+:: Time out in seconds for the exec command, default: 300
#
# === Example usage
#
#   git::clone { 'my_clone_name':
#       directory => '/path/to/clone/container',
#       origin    => 'http://blabla.org/core.git',
#       branch    => 'the_best_branch'
#   }
#
# Will clone +http://blabla.org/core.git+ branch +the_best_branch+ at
#  +/path/to/clone/container/core+
#
#   # Example: check out from gerrit:
#   git::clone { 'analytics/wikimetrics':
#       directory = '/srv/wikimetrics',
#   }
#
define git::clone(
    $directory,
    $origin=undef,
    $branch='',
    $ssh='',
    $ensure='present',
    $owner='root',
    $group='root',
    $shared=false,
    $timeout='300',
    $depth='full',
    $recurse_submodules=false,
    $mode=undef) {

    $gerrit_url_format = 'https://gerrit.wikimedia.org/r/p/%s.git'

    $remote = $origin ? {
        undef   => sprintf($gerrit_url_format, $title),
        default => $origin,
    }

    if $mode == undef {
        $file_mode = $shared ? {
            true    => '2755',
            default => '0755',
        }
    } elsif $shared and $mode !~ /^277\d/ {
        fail("Shared repositories must leave 'mode' unspecified' or set to 277?, specified as octal.")
    } else {
        $file_mode = $mode
    }

    case $ensure {
        'absent': {
            # make sure $directory does not exist
            file { $directory:
                ensure  => 'absent',
                recurse => true,
                force   => true,
            }
        }

        # otherwise clone the repository
        default: {
            $recurse_submodules_arg = $recurse_submodules ? {
                true    => '--recurse-submodules ',
                default => '',
            }
            # if branch was specified
            if $branch {
                $brancharg = "-b $branch "
            }
            # else don't checkout a non-default branch
            else {
                $brancharg = ''
            }
            if $ssh {
                $env = "GIT_SSH=$ssh"
            }

            $deptharg = $depth ?  {
                'full'  => '',
                default => " --depth=$depth"
            }

            $shared_arg = $shared ? {
                true    => "-c core.sharedRepository=${file_mode}"
                default => '',
            }

            # set PATH for following execs
            Exec { path => '/usr/bin:/bin' }
            # clone the repository
            exec { "git_clone_${title}":
                command     => "git ${shared_arg} clone ${recurse_submodules_arg}${brancharg}${remote}${deptharg} $directory",
                logoutput   => on_failure,
                cwd         => '/tmp',
                environment => $env,
                creates     => "$directory/.git/config",
                user        => $owner,
                group       => $group,
                timeout     => $timeout,
                require     => Package['git-core'],
                notify      => $notify_submodule_exec,
            }

            if (!defined(File[$directory])) {
                file { $directory:
                    ensure  => 'directory',
                    mode    => $file_mode,
                    owner   => $owner,
                    group   => $group,
                    require => Exec["git_clone_${title}"],
                }
            }

            if ( $shared ) {
                # Changing an existing git repository to be shared by a group is ugly,
                # but here's how you do it without causing log churn.
                exec { "git_clone_${title}_configure_shared_repository":
                    command => 'git config --local core.sharedRepository group',
                    unless  => 'test $(git config --local core.sharedRepository) = group',
                    cwd     => $directory,
                    require => Exec["git_clone_${title}"],
                    notify  => Exec["git_clone_${title}_set_group_owner"],
                }

                exec { "git_clone_${title}_set_group_owner":
                    command => "chgrp -R '${group}' '${directory}'",
                    onlyif  => "find '${directory}' ! -group '${group}'",
                    cwd     => $directory,
                    require => Exec["git_clone_${title}_configure_shared_repository"],
                    notify  => Exec["git_clone_${title}_group_writable"],
                }

                exec { "git_clone_${title}_group_writable":
                    command => "find '${directory}' ! -perm -g=wX,o= -exec chmod g+wX,o= '{}' ';'",
                    onlyif  => "find '${directory}' ! -perm -g=wX,o=",
                    cwd     => $directory,
                    require => Exec["git_clone_${title}_set_group_owner"],
                    notify  => Exec["git_clone_${title}_sgid_bit"],
                }

                exec { "git_clone_${title}_sgid_bit":
                    command => "find '${directory}' -mindepth 1 -type d -and ! -perm -g+s -exec chmod g+s '{}' ';'",
                    onlyif  => "find '${directory}' -mindepth 1 -type d -and ! -perm -g+s",
                    cwd     => $directory,
                    require => Exec["git_clone_${title}_group_writable"],
                }
            }

            # pull if $ensure == latest and if there are changes to merge in.
            if $ensure == 'latest' {
                exec { "git_pull_${title}":
                    cwd       => $directory,
                    command   => "git ${shared_arg} pull ${recurse_submodules_arg}--quiet${deptharg}",
                    logoutput => on_failure,
                    # git diff --quiet will exit 1 (return false)
                    #  if there are differences
                    unless    => 'git fetch && git diff --quiet remotes/origin/HEAD',
                    user      => $owner,
                    group     => $group,
                    require   => Exec["git_clone_${title}"],
                    notify    => $notify_submodule_exec,
                }
                # If we want submodules up to date, then we need
                # to run git submodule update --init after
                # git pull is run.
                if $recurse_submodules {
                    exec { "git_submodule_update_${title}":
                        command     => "git ${shared_arg} submodule update --init",
                        cwd         => $directory,
                        environment => $env,
                        refreshonly => true,
                        subscribe   => Exec["git_pull_${title}"],
                    }
                }
            }

        }
    }
}
