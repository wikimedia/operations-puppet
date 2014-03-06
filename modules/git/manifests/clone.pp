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
# $+mode+:: Permission mode of $directory, default: 0755
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
    $timeout='300',
    $depth='full',
    $submodules_enabled=false,
    $mode=0755) {

    $gerrit_url_format = 'https://gerrit.wikimedia.org/r/p/%s.git'

    $remote = $origin ? {
        undef   => sprintf($gerrit_url_format, $title),
        default => $origin,
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

            # If $submodules_enabled, then make
            # the clone and pull execs notify
            # the git submodule update --init command.
            $notify_submodule_exec = $submodules_enabled ? {
                true    => Exec["git_submodule_update_${title}"],
                default => undef,
            }

            # set PATH for following execs
            Exec { path => '/usr/bin:/bin' }
            # clone the repository
            exec { "git_clone_${title}":
                command     => "git clone ${brancharg}${remote}${deptharg} $directory",
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
                    mode    => $mode,
                    owner   => $owner,
                    group   => $group,
                    require => Exec["git_clone_${title}"],
                }
            }


            # pull if $ensure == latest and if there are changes to merge in.
            if $ensure == 'latest' {
                exec { "git_pull_${title}":
                    cwd       => $directory,
                    command   => "git pull --quiet${deptharg}",
                    logoutput => on_failure,
                    # git diff --quiet will exit 1 (return false)
                    #  if there are differences
                    unless    => 'git fetch && git diff --quiet remotes/origin/HEAD',
                    user      => $owner,
                    group     => $group,
                    require   => Exec["git_clone_${title}"],
                    notify    => $notify_submodule_exec,
                }
            }

            # this will only happen if the git clone or git pull
            # exec run and notify this.
            exec { "git_submodule_update_${title}":
                command     => 'git submodule update --init',
                cwd         => $directory,
                environment => $env,
                refreshonly => true,
            }
        }
    }
}
