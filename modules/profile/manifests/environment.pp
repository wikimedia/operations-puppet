# SPDX-License-Identifier: Apache-2.0
# @summary Sets up the base environment for all hosts (profile, editor, sysctl, etc)
# @param ls_aliases if true, will setup the ll/la aliases
# @param export_systemd_env if true, add login scripts to ensure systemd environment.d variables are exported
# @param custom_bashrc when set, will replace the system bashrc with the given template (as a path)
# @param custom_skel_bashrc when set, will replace the system skel bashrc with the given template (as a path)
# @param custom_skel_zshrc when set, will replace the system skel zshrc with the given template (as a path)
# @param editor choose the default editor, if 'use_default' will use the system's default
# @param wikimedia_domains List of WMF domains configured on the caching servers (mostly internally hosted)
# @param no_proxy_domains  List of exceptions to also not use the proxy for (e.g. localhost)
# @param skip_domains Excludes domains from no_proxy_domains (e.g. if this list comes from a more
#                     general list, but one of the domains should not skip the proxy after all).
# @param profile_scripts list of script names to be added to /etc/profile.d and their source
# @param variables a list of environment variables to set globally
#
class profile::environment (
    Boolean                          $ls_aliases         = lookup('profile::environment::ls_aliases'),
    Boolean                          $export_systemd_env = lookup('profile::environment::export_systemd_env'),
    Enum['vim', 'use_default']       $editor             = lookup('profile::environment::editor'),
    Optional[String[1]]              $custom_skel_bashrc = lookup('profile::environment::custom_skel_bashrc'),
    Optional[String[1]]              $custom_skel_zshrc  = lookup('profile::environment::custom_skel_zshrc'),
    Optional[String[1]]              $custom_bashrc      = lookup('profile::environment::custom_bashrc'),
    Array[Stdlib::Fqdn]              $wikimedia_domains  = lookup('profile::environment::wikimedia_domains'),
    Array[Stdlib::Host]              $no_proxy_domains   = lookup('profile::environment::no_proxy_domains'),
    Array[Stdlib::Host]              $skip_domains       = lookup('profile::environment::skip_domains'),
    Hash[String, Stdlib::Filesource] $profile_scripts    = lookup('profile::environment::profile_scripts'),
    Hash[String[1], String[1]]       $variables          = lookup('profile::environment::variables'),
) {
    ensure_packages(['vim', 'zsh'])
    # See the following for some semantics on no_proxy
    # https://about.gitlab.com/blog/2021/01/27/we-need-to-talk-no-proxy
    $_no_proxy_domains = $wikimedia_domains + $no_proxy_domains - $skip_domains
    $_variables = $_no_proxy_domains.empty ? {
        true    => $variables,
        default => $variables + {
            'no_proxy' => $_no_proxy_domains.join(','),
            'NO_PROXY' => $_no_proxy_domains.join(',')
        },
    }
    if $ls_aliases {
        exec { 'uncomment root bash aliases':
            path    => '/bin:/usr/bin',
            command => "sed -i '
                    /^#alias ll=/ s/^#//
                    /^#alias la=/ s/^#//
                ' /root/.bashrc",
            onlyif  => "grep -q '^#alias ll' /root/.bashrc",
        }
    }

    if $custom_bashrc {
        file { '/etc/bash.bashrc':
                content => template($custom_bashrc),
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
        }
    }
    if $custom_skel_bashrc {
        file { '/etc/skel/.bashrc':
                content => template($custom_skel_bashrc),
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
        }
    }
    if $custom_skel_bashrc {
        file { '/etc/skel/.zshrc':
                content => template($custom_skel_zshrc),
                owner   => 'root',
                group   => 'root',
                mode    => '0644',
        }
    }

    if $editor != 'use_default' {
        file { '/etc/alternatives/editor':
            ensure => link,
            target => "/usr/bin/${editor}",
        }
    }

    $profile_scripts.each |$script, $source| {
        file {
            "/etc/profile.d/${script}":
                ensure => file,
                owner  => 'root',
                group  => 'root',
                mode   => '0444',
                source => $source,
        }
    }

    file { '/etc/zsh/zshenv':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['zsh'],
        content => template('profile/environment/zshenv.erb'),
    }
    file { '/etc/profile.d/systemd-environment.sh':
        ensure => stdlib::ensure($export_systemd_env, 'file'),
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/environment/systemd-environment.sh',
    }

    ### Settings commons to all realms

    $wikimedia_cluster = $::realm ? {
        'labs'  => "labs\n",
        default => "${::site}\n",
    }

    file { '/etc/wikimedia-cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $wikimedia_cluster,
    }

    # script to generate ssh fingerprints of the server
    file { '/usr/local/bin/gen_fingerprints':
        source => 'puppet:///modules/base/environment/gen_fingerprints',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Global vim defaults
    file { '/etc/vim/vimrc.local':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/base/environment/vimrc.local',
        require => Package['vim'],
    }

    # Global environment variables
    unless $_variables.empty {
        systemd::environment { 'base-wmf-environment':
            priority  => 10,
            variables => $_variables,
        }
    }
}
