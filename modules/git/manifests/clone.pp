# @summary Creates a git clone of a specified origin into a top level directory.
#
# @param directory path to clone the repository into.
#
# === Optional parameters
#
# @param origin If this is not specified, the $title repository will be
#               checked out from gerrit using a default gerrit url.
#               If you set this, please specify the full repository url.
# @param branch Branch you would like to check out.
# @param git_tag Tag you would like to check out. Only one of 'branch' or 'git_tag'
#                can be used.
# @param ensure 'absent', 'present', or 'latest'.
#             - 'present' will just clone once.
#             - 'latest' will update the checkout according to 'update_method' (see below).
#             - 'absent' will ensure the directory is deleted.
# @param owner Owner of $directory. git commands will be run by this user.
# @param group Group owner of $directory.
# @param bare  $directory is the GIT_DIR itself. Workspace is not checked out.
# @param recurse_submodules If true, git recurse submodules
# @param shared Enable git's core.sharedRepository=group setting for sharing the
#               repository between serveral users, default: false
# @param mode Permission mode of $directory, default: 2755 if shared, 0755 otherwise
# @param ssh SSH command/wrapper to use when checking out
# @param timeout  Time out in seconds for the git clone command
# @param depth the depth to clone if not present use full
# @param source Where to request the repo from, if $origin isn't specified
#               'phabricator', 'github', 'gitlab' and 'gerrit' accepted
# @param environment_variables An array of additional environment variables to pass
#                              to the git exec.
# @param remote_name the remote name used when setting the url
# @param update_method Specifies the method to use to update the checkout when
#                      The value must be _pull_ or _checkout_.
#                      - 'pull' will perform a merging pull if upstream changes.
#                      - 'checkout' will perform a forced checkout of the designated
#                      branch if upstream changes.
#                      Defaults to 'pull' for compatibility, but 'checkout' is the
#                      recommended value for clones that you want to be automatically
#                      maintained.
#
# @example
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
    Stdlib::Unixpath                    $directory,
    Enum['absent', 'latest', 'present'] $ensure                = 'present',
    Enum['pull', 'checkout']            $update_method         = 'pull',
    String[1]                           $owner                 = 'root',
    String[1]                           $group                 = 'root',
    Boolean                             $shared                = false,
    Integer                             $timeout               = 300,
    Boolean                             $bare                  = false,
    Boolean                             $recurse_submodules    = false,
    String[1]                           $source                = 'gerrit',
    Array[String[1]]                    $environment_variables = [],
    String[1]                           $remote_name           = 'origin',
    Optional[Integer[1]]                $depth                 = undef,
    Optional[String[1]]                 $origin                = undef,
    Optional[String[1]]                 $branch                = undef,
    Optional[String[1]]                 $git_tag               = undef,
    Optional[String[1]]                 $ssh                   = undef,
    Optional[Stdlib::Filemode]          $mode                  = undef,
) {

    ensure_packages('git')

    $default_url_format = $source ? {
        'phabricator'      => 'https://phabricator.wikimedia.org/diffusion/%.git',
        'github'           => 'https://github.com/wikimedia/%s.git',
        'github-toolforge' => 'https://github.com/toolforge/%s.git',
        'gerrit'           => 'https://gerrit.wikimedia.org/r/%s',
        'gitlab'           => 'https://gitlab.wikimedia.org/%s.git',
        default            => 'https://gerrit.wikimedia.org/r/%s',
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

    $umask = mode2umask($file_mode)

    if $branch and $git_tag {
        fail('"branch" and "git_tag" cannot be used together.  Choose one')
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
            $recurse_submodules_arg = $recurse_submodules.bool2str('--recurse-submodules', '')

            $branch_or_tag = $branch.lest || { $git_tag }
            $brancharg = $branch_or_tag.then |$x| { "-b ${branch_or_tag}" }
            $env = $ssh ? {
                undef   => $environment_variables,
                default => $environment_variables << "GIT_SSH=${ssh}",
            }

            $deptharg = $depth.then |$x| { "--depth=${depth}" }

            if $bare == true {
                $barearg = '--bare'
                $git_dir = $directory
            } else {
                $barearg = ''
                $git_dir = "${directory}/.git"
            }


            $shared_arg = $shared.bool2str('-c core.sharedRepository=group', '')
            $git = '/usr/bin/git'

            $clone_cmd = @("COMMAND"/L)
            ${git} ${shared_arg} clone \
                ${recurse_submodules_arg} \
                ${brancharg} \
                ${remote} \
                ${deptharg} \
                ${barearg} \
                ${directory}
            |- COMMAND

            # clone the repository
            exec { "git_clone_${title}":
                command     => $clone_cmd.split(/\s+/).join(' '),
                provider    => shell,
                logoutput   => on_failure,
                cwd         => '/tmp',
                environment => $env,
                creates     => "${git_dir}/config",
                umask       => $umask,
                user        => $owner,
                group       => $group,
                timeout     => $timeout,
                require     => Package['git'],
            }

            # FIXME: this is most probably to ensure the holding directory has
            # the proper mode, owner and group. However:
            # - git clone above should do it for us.
            # - git clone will fail when $directory exists so that should
            # happen after git clone.
            #
            # It most probably should always be executed in case mode, owner
            # and/or group change.
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
            exec { "git_set_${remote_name}_${title}":
                cwd       => $directory,
                command   => "${git} remote set-url ${remote_name} ${remote}",
                provider  => shell,
                logoutput => on_failure,
                unless    => "[ \"\$(${git} remote get-url ${remote_name})\" = \"${remote}\" ]",
                umask     => $umask,
                user      => $owner,
                group     => $group,
                require   => Exec["git_clone_${title}"],
            }

            # if $ensure == latest, update the checkout when there are upstream changes.
            if $ensure == 'latest' {
                $local_branch_expression = $branch_or_tag.lest || {
                    # Use the default branch name obtained from the remote.
                    "$(git remote show ${remote_name} | awk -F': ' '\$1~/HEAD branch/ {print \$2; exit}')"
                }
                $ref_to_check = $git_tag ? {
                    undef => $branch ? {
                        undef   => "remotes/${remote_name}/HEAD",
                        default => "remotes/${remote_name}/${branch}",
                    },
                    default => "refs/tags/${git_tag}",
                }
                $checkout_cmd = @("COMMAND"/L)
                ${git} ${shared_arg} checkout --force --quiet \
                    -B ${local_branch_expression} \
                    ${ref_to_check} \
                    ${recurse_submodules_arg}
                |- COMMAND
                $update_cmd = $update_method ? {
                    'checkout' => $checkout_cmd,
                    'pull'     => "${git} ${shared_arg} pull ${recurse_submodules_arg} --quiet ${deptharg}",
                }.split(/\s+/).join(' ')
                exec { "git_${update_method}_${title}":
                    cwd       => $directory,
                    command   => $update_cmd,
                    provider  => shell,
                    logoutput => on_failure,
                    # git diff --quiet will exit 1 (return false)
                    #  if there are differences
                    unless    => "${git} fetch --tags --prune --prune-tags && ${git} diff --quiet ${ref_to_check}",
                    umask     => $umask,
                    user      => $owner,
                    group     => $group,
                    require   => Exec["git_set_${remote_name}_${title}"],
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
                        umask       => $umask,
                        user        => $owner,
                        group       => $group,
                        subscribe   => Exec["git_${update_method}_${title}"],
                    }
                }
            }
        }
    }
}
