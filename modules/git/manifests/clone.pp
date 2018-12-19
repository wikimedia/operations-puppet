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
# $+bare+:: $directory is the GIT_DIR itself. Workspace is not checked out.
#           Default: false
# $+recurse_submodules:: If true, git
# $+shared+:: Enable git's core.sharedRepository=group setting for sharing the
# repository between serveral users, default: false
# $+umask+:: umask value that git operations should run under,
#            default 002 if shared, 022 otherwise.
# $+mode+:: Permission mode of $directory, default: 2755 if shared, 0755 otherwise
# $+ssh+:: SSH command/wrapper to use when checking out, default: ''
# $+timeout+:: Time out in seconds for the exec command, default: 300
# $+source+:: Where to request the repo from, if $origin isn't specified
#             'phabricator', 'github' and 'gerrit' accepted, default is 'gerrit'
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
#  +/path/to/clone/container/+
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
    $bare=false,
    $recurse_submodules=false,
    $umask=undef,
    $mode=undef,
    $source='gerrit') {

    require_package('git')

    $default_url_format = $source ? {
        'phabricator' => 'https://phabricator.wikimedia.org/diffusion/%.git',
        'github'      => 'https://github.com/wikimedia/%s.git',
        'gerrit'      => 'https://gerrit.wikimedia.org/r/%s',
        default       => 'https://gerrit.wikimedia.org/r/%s',
    }

    $remote = $origin ? {
        undef   => sprintf($default_url_format, $title),
        default => $origin,
    }

    if $mode == undef {
        $file_mode = $shared ? {
            true    => '2775',
            default => '0755',
        }
    } elsif $shared and $mode !~ /^277\d/ {
        fail('Shared repositories must leave "mode" unspecified or set to 277?, specified as octal.')
    } else {
        $file_mode = $mode
    }

    if $umask == undef {
        $git_umask = $shared ? {
            true    => '002',
            default => '022',
        }
    } elsif $shared and $umask !~ /^00\d$/ {
        fail('Shared repositories must leave "umask" unspecified or set to 00?, specified as octal.')
    } else {
        $git_umask = $umask
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
            if !empty($branch) {
                $brancharg = "-b ${branch} "
            }
            # else don't checkout a non-default branch
            else {
                $brancharg = ''
            }
            if !empty($ssh) {
                $env = "GIT_SSH=${ssh}"
            } else {
                $env = undef
            }

            $deptharg = $depth ?  {
                'full'  => '',
                default => " --depth=${depth}"
            }

            if $bare == true {
                $barearg = ' --bare'
                $git_dir = $directory
            } else {
                $barearg = ''
                $git_dir = "${directory}/.git"
            }

            if $shared {
                $shared_arg = '-c core.sharedRepository=group'
            } else {
                $shared_arg = ''
            }

            $git = '/usr/bin/git'

            # set PATH for following execs
            Exec { path => '/usr/bin:/bin' }
            # clone the repository
            exec { "git_clone_${title}":
                command     => "${git} ${shared_arg} clone ${recurse_submodules_arg}${brancharg}${remote}${deptharg}${barearg} ${directory}",
                provider    => shell,
                logoutput   => on_failure,
                cwd         => '/tmp',
                environment => $env,
                creates     => "${git_dir}/config",
                user        => $owner,
                group       => $group,
                umask       => $git_umask,
                timeout     => $timeout,
                require     => Package['git'],
            }

            if (!defined(File[$directory])) {
                file { $directory:
                    ensure => 'directory',
                    mode   => $file_mode,
                    owner  => $owner,
                    group  => $group,
                    before => Exec["git_clone_${title}"],
                }
            }

            # pull if $ensure == latest and if there are changes to merge in.
            if $ensure == 'latest' {
                $remote_to_check = $branch ? {
                    ''      => 'remotes/origin/HEAD',
                    default => "remotes/origin/${branch}",
                }
                exec { "git_pull_${title}":
                    cwd       => $directory,
                    command   => "${git} ${shared_arg} pull ${recurse_submodules_arg}--quiet${deptharg}",
                    provider  => shell,
                    logoutput => on_failure,
                    # git diff --quiet will exit 1 (return false)
                    #  if there are differences
                    unless    => "${git} fetch && ${git} diff --quiet ${remote_to_check}",
                    user      => $owner,
                    group     => $group,
                    umask     => $git_umask,
                    require   => Exec["git_clone_${title}"],
                }
                # If we want submodules up to date, then we need
                # to run git submodule update --init after
                # git pull is run.
                if $recurse_submodules {
                    exec { "git_submodule_update_${title}":
                        command     => "${git} ${shared_arg} submodule update --init",
                        provider    => shell,
                        cwd         => $directory,
                        environment => $env,
                        refreshonly => true,
                        user        => $owner,
                        group       => $group,
                        umask       => $git_umask,
                        subscribe   => Exec["git_pull_${title}"],
                    }
                }
            }

        }
    }
}
