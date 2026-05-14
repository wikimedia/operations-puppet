# SPDX-License-Identifier: Apache-2.0
# == Class: phabricator::config
#
# Sets up the phabricator config files in /etc. This is a separate subclass so
# that it can be imported into the aphlict servers without installing the full
# phabricator class.
#
# === Parameters
#
# [*phabdir*]
#    The path on disk to clone the needed repositories
#
# [*deploy_user*]
#     The username that is used for scap deployments
#
# [*deploy_target*]
#     The name of the scap3 deployment repo, e.g. phabricator/deployment
#
# [*config_deploy_vars*]
#     Variables used by scap3 during config deployment.
#
# [*storage_user*]
#     Specify to use a different user for schema upgrades and database
#     maintenance
#     Requires: storage_pass
#
# [*storage_pass*]
#     Specify to use a different password for schema upgrades and database
#     maintenance
#     Requires: storage_user
#
# [*manage_scap_user*]
#     Specify whether to create a User resource for the $deploy_user.
#     This should be set to false if you have defined the user elsewhere.
#     Default: true
class phabricator::config (
    Stdlib::Unixpath $phabdir            = '/srv/phab',
    String           $deploy_root        = undef,
    String           $deploy_user        = undef,
    String           $deploy_target      = 'phabricator/deployment',
    String           $storage_user       = '',
    String           $storage_pass       = '',
    Boolean          $manage_scap_user   = undef,
    Hash             $config_deploy_vars = {},
) {
    $base_requirements = [Package[$deploy_target]]

    $sudo_env_keep = [
        'SCAP_REVS_DIR',
        'SCAP_FINAL_PATH',
        'SCAP_REV_PATH',
        'SCAP_CURRENT_REV_DIR',
        'SCAP_DONE_REV_DIR',
    ].join(' ')

    $sudo_scap_defaults = "Defaults:${deploy_user} env_keep+=\"${sudo_env_keep}\"\n"

    file { '/etc/sudoers.d/scap_sudo_defaults':
        ensure       => file,
        mode         => '0440',
        owner        => 'root',
        group        => 'root',
        content      => $sudo_scap_defaults,
        validate_cmd => '/usr/sbin/visudo -cqf %',
    }

    $sudo_rules = [
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_config_deploy',
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_promote',
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_rollback',
        'ALL=(root) NOPASSWD: /usr/local/sbin/phab_deploy_finalize',
    ]

    scap::target { $deploy_target:
        deploy_user => $deploy_user,
        key_name    => 'phabricator',
        manage_user => $manage_scap_user,
        require     => File['/usr/local/sbin/phab_deploy_finalize'],
        sudo_rules  => $sudo_rules,
    }

    # Provide secrets and host-specific configuration that scap3 will use for
    # its config deploy templates
    file { '/etc/phabricator':
        ensure => directory,
        owner  => 'root',
        group  => $deploy_user,
        mode   => '0750',
    }

    file { '/etc/phabricator/config.yaml':
        ensure  => present,
        owner   => 'root',
        group   => $deploy_user,
        mode    => '0640',
        content => $config_deploy_vars.to_yaml(),
    }

    file { '/etc/phabricator/script-vars':
        ensure  => present,
        content => template('phabricator/script-vars.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
    }

    file { $phabdir:
        ensure  => link,
        target  => $deploy_root,
        require => Package[$deploy_target],
    }

    file { "${phabdir}/phabricator/scripts/":
        owner   => $deploy_user,
        group   => $deploy_user,
        mode    => '0754',
        recurse => true,
        require => $base_requirements,
    }

    file { "${phabdir}/phabricator/scripts/mail/":
        mode    => '0755',
        recurse => true,
        require => $base_requirements,
    }

    file { '/usr/local/sbin/phab_deploy_config_deploy':
        content => file('phabricator/phab_deploy_config_deploy.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_promote':
        content => file('phabricator/phab_deploy_promote.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_finalize':
        content => template('phabricator/phab_deploy_finalize.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

    file { '/usr/local/sbin/phab_deploy_rollback':
        content => file('phabricator/phab_deploy_rollback.sh'),
        owner   => 'root',
        group   => 'root',
        mode    => '0700',
    }

}
