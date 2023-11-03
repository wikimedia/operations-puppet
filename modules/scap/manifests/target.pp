# SPDX-License-Identifier: Apache-2.0
# == Define: scap::target
#
# Sets up a scap3 target for a deployment repository.
# This will include ths scap package and ferm fules,
# ensure that the $deploy_user has proper sudo rules
# and public key installed.
#
# === Parameters
#
# [*ensure*]
#   present or absent to setup or remove
#
# [*deploy_user*]
#   user that will be used for deployments
#
# [*key_name*]
#   The name of a keyholder ssh key used to access this deployment target.
#   This should correspond to a key which is defined in keyholder::agent
#   (which for prod are defined in hieradata/role/common/deployment_server/kubernetes.yaml)
#   Warning: If key_name is left undefined, then you must define the correct
#   ssh::userkey for your deploy_user so that scap can connect to the target
#   from the deployment server with a corresponding key in keyholder.
#
# [*service_name*]
#   service name that should be allowed to be restarted via sudo by
#   deploy_user.  Default: undef.
#
# [*additional_services_names*]
#   An array of additional services to apply sudo rules to by
#   deploy_user. Default: []
#
# [*package_name*]
#   the name of the scap3 deployment package Default: $title
#
# [*manage_user*]
#   Specify whether to create a User resource for the $deploy_user.
#   This should be set to false if you have defined the user elsewhere.
#   Default: true
#
# [*manage_ssh_key*]
#   If a ssh::userkey should be declared for the $deploy_user.
#   Default: $manage_user
#
# [*sudo_rules*]
#   An array of additional sudo rules pertaining to the service to install on
#   the target node. Default: []
#
# Usage:
#
#   scap::target { 'eventlogging/eventlogging':
#       deploy_user => 'eventlogging',
#   }
#
#
#   scap::target { 'dumps/dumps':
#       deploy_user => 'datasets',
#       manage_user => false,
#       key_name    => 'dumps',
#   }
#
define scap::target(
    String $deploy_user,
    String $key_name                            = $deploy_user,
    Wmflib::Ensure   $ensure                    = 'present',
    Optional[String] $service_name              = undef,
    Array[String]    $additional_services_names = [],
    String           $package_name              = $title,
    Boolean          $manage_user               = true,
    Boolean          $manage_ssh_key            = $manage_user,
    Array[String]    $sudo_rules                = [],
) {
    # Include scap3 and ssh ferm rules.
    include scap
    include scap::ferm

    if !$service_name and !empty($additional_services_names) {
        fail('service_name must be set if additional_services_names is set')
    }

    if $manage_user {
        if !defined(Group[$deploy_user]) {
            group { $deploy_user:
                ensure => $ensure,
                system => true,
                before => User[$deploy_user],
            }
        }
        if !defined(User[$deploy_user]) {
            user { $deploy_user:
                ensure     => $ensure,
                shell      => '/bin/bash',
                home       => "/var/lib/${deploy_user}",
                system     => true,
                membership => 'minimum',
                groups     => [$deploy_user],
            }
            file { "/var/lib/${deploy_user}":
                ensure => stdlib::ensure($ensure, 'directory'),
                owner  => $deploy_user,
                group  => $deploy_user,
                mode   => '0755',
            }
        }
    }
    if $manage_ssh_key {
        if !defined(Ssh::Userkey[$deploy_user]) {
            $key_name_safe = regsubst($key_name, '\W', '_', 'G')

            ssh::userkey { $deploy_user:
                ensure  => $ensure,
                content => secret("keyholder/${key_name_safe}.pub"),
            }
        } else {
            notice("mange_ssh_key=true but ssh::userkey ${deploy_user} already defined.")
        }
    }

    if $::realm == 'labs' {
        $deployment_host = lookup('scap::deployment_server')
        $deployment_ip = dnsquery::a($deployment_host)[0]

        if !defined(Security::Access::Config["scap-allow-${deploy_user}"]) {
            # Allow $deploy_user login from scap deployment host.
            # adds an exception in /etc/security/access.conf
            # to work around labs-specific restrictions
            security::access::config { "scap-allow-${deploy_user}":
                ensure   => $ensure,
                content  => "+ : ${deploy_user} : ${deployment_ip}\n",
                priority => 60,
            }
        }
        if !defined(Security::Access::Config['scap-allow-scap']) {
            # Allow scap login from scap deployment host.
            # adds an exception in /etc/security/access.conf
            # to work around labs-specific restrictions
            security::access::config { 'scap-allow-scap':
                ensure   => $ensure,
                content  => "+ : scap : ${deployment_ip}\n",
                priority => 65,
            }
        }
    }

    # Allow deploy user user to sudo -u $user, and to sudo /usr/sbin/service
    # if $service_name is defined.
    #
    # Two sets of privileges are defined: one for scap to able to sudo -u $user,
    # which should be defined only once per node, and another for restarting
    # whichever services are being deployed.
    #
    # NOTE: sudo -u $user is currently needed by scap3.
    # TODO: Remove this when it is no longer needed.

    if !defined(Sudo::User["scap_${deploy_user}"]) {

        sudo::user { "scap_${deploy_user}":
            ensure     => $ensure,
            user       => $deploy_user,
            privileges => ["ALL=(${deploy_user}) NOPASSWD: ALL"],
        }
    }

    if $service_name {
        ($additional_services_names + [$service_name]).each |String $svc_name| {
            $service_privileges = [
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} start",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} stop",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} restart",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} reload",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} status",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} try-restart",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} force-reload",
                "ALL=(root) NOPASSWD: /usr/sbin/service ${svc_name} graceful-stop",
                # T343447 Required for Scap to be able to disable services on secondary targets (/usr/sbin/service does
                # not offer enable/disable operations)
                "ALL=(root) NOPASSWD: /bin/systemctl enable ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl disable ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl start ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl stop ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl restart ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl reload ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl status ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl try-restart ${svc_name}",
                "ALL=(root) NOPASSWD: /bin/systemctl reload-or-restart ${svc_name}",
            ]

            if !defined(Sudo::User["scap_${deploy_user}_${svc_name}"]) {
                sudo::user { "scap_${deploy_user}_${svc_name}":
                    ensure     => $ensure,
                    user       => $deploy_user,
                    privileges => $service_privileges,
                }
            }
        }
    }

    if !empty($sudo_rules) {
        $sudo_rule_name = regsubst("scap_sudo_rules_${deploy_user}_${title}", '/', '_', 'G')

        if !defined(Sudo::User[$sudo_rule_name]) {
                sudo::user { $sudo_rule_name:
                    ensure     => $ensure,
                    user       => $deploy_user,
                    privileges => $sudo_rules,
                }
        }
    }

    if $::realm == 'labs' {
        $require_package = $manage_user ? {
            true    => User[$deploy_user],
            default => [],
        }
    } else {
        $require_package = User[$deploy_user]
    }

    # Have scap actually deploy the source, restart the service if needed, etc
    # Assume $deploy_user already has sudo permissions because of the block above.
    package { $package_name:
        ensure          => $ensure,
        install_options => [{
            owner => $deploy_user
        }],
        provider        => 'scap3',
        require         => $require_package,
    }

    # XXX: Temporary work-around for switching services from Trebuchet to Scap3
    # The Scap3 provider doesn't touch the target dir if it's already a git repo
    # which means that even after switching the provider we end up with the
    # wrong user (root) owning it. Therefore, as a temporary measure we chown
    # the target dir's parent so that the subsequent invocation of deploy-local
    # is able to create the needed dirs and symlinks
    $chown_user = "${deploy_user}:${deploy_user}"
    $name_array = split($package_name, '/')
    $pkg_root = inline_template(
        '<%= @name_array[0,@name_array.size - 1].join("/") %>'
    )
    $chown_target = "/srv/deployment/${pkg_root}"
    $exec_name = "chown ${chown_target} for ${deploy_user}"
    if !defined(Exec[$exec_name]) {
        if $::realm == 'labs' {
            $require_exec = $manage_user ? {
                true    => [
                    User[$deploy_user],
                    Group[$deploy_user]
                ],
                default => undef,
            }
        } else {
            $require_exec = [User[$deploy_user], Group[$deploy_user]]
        }

        exec { $exec_name:
            command => "/bin/chown -R ${chown_user} ${chown_target}",
            # perform the chown only if root is the effective owner
            onlyif  => "/usr/bin/test -O /srv/deployment/${package_name}",
            require => $require_exec,
        }
    }
}
