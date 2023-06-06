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
# $+origin+:: If this is not specified, the $title repository will be
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
#             'phabricator', 'github', 'gitlab' and 'gerrit' accepted, default is 'gerrit'
# $+environment_variables+:: An array of additional environment variables to pass
#                           to the git exec.
# $+update_method+:: Specifies the method to use to update the checkout when
#                    $ensure is _latest_.  The value must be _pull_ or _checkout_.
#                    - _pull_ will perform a merging pull if upstream changes.
#                    - _checkout_ will perform a forced checkout of the designated
#                      branch if upstream changes.
#                    Defaults to 'pull' for compatibility, but 'checkout' is the
#                    recommended value for clones that you want to be automatically
#                    maintained.
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
#   git::clone { 'analytics/wikistats2':
#       directory => '/srv/wikistats2',
#   }
#
#   # Example: check out from gitlab:
#   git::clone { 'repos/cloud/wikistats':
#       directory => '/srv/wikistats',
#       source    => 'gitlab',
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
    $source='gerrit',
    $environment_variables=[],
    Enum['pull', 'checkout'] $update_method = 'pull',
) {

    ensure_packages('git')

    $default_url_format = $source ? {
        'phabricator' => 'https://phabricator.wikimedia.org/diffusion/%.git',
        'github'      => 'https://github.com/wikimedia/%s.git',
        'gerrit'      => 'https://gerrit.wikimedia.org/r/%s',
        'gitlab'      => 'https://gitlab.wikimedia.org/%s.git',
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
                $env = $environment_variables << "GIT_SSH=${ssh}"
            } else {
                $env = $environment_variables
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

            # Ensure that the URL for 'origin' is always up-to-date.
            exec { "git_set_origin_${title}":
                cwd       => $directory,
                command   => "${git} remote set-url origin ${remote}",
                provider  => shell,
                logoutput => on_failure,
                unless    => "[ \"\$(${git} remote get-url origin)\" == \"${remote}\" ]",
                user      => $owner,
                group     => $group,
                umask     => $git_umask,
                require   => Exec["git_clone_${title}"],
            }

            # if $ensure == latest, update the checkout when there are upstream changes.
            if $ensure == 'latest' {
                $local_branch_expression = $branch ? {
                    ''      => '$(git remote show origin | awk -F": " \'$1~/HEAD branch/ {print $2; exit}\')',
                    default => $branch,
                }
                $ref_to_check = $branch ? {
                    ''      => 'remotes/origin/HEAD',
                    default => "remotes/origin/${branch}",
                }
                $update_cmd = $update_method ? {
                    'checkout' => "${git} ${shared_arg} checkout --force -B ${local_branch_expression} ${ref_to_check} ${recurse_submodules_arg}--quiet",
                    'pull'     => "${git} ${shared_arg} pull ${recurse_submodules_arg}--quiet${deptharg}",
                }
                exec { "git_${update_method}_${title}":
                    cwd       => $directory,
                    command   => $update_cmd,
                    provider  => shell,
                    logoutput => on_failure,
                    # git diff --quiet will exit 1 (return false)
                    #  if there are differences
                    unless    => "${git} fetch --prune --prune-tags && ${git} diff --quiet ${ref_to_check}",
                    user      => $owner,
                    group     => $group,
                    umask     => $git_umask,
                    require   => Exec["git_set_origin_${title}"],
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
                        subscribe   => Exec["git_${update_method}_${title}"],
                    }
                }
            }

        }
    }
}
