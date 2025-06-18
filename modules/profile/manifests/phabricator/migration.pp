# SPDX-License-Identifier: Apache-2.0
# Allow rsyncing phabricator data to other servers for hardware migration
# and setup scap user before deploying the first time to a new or reimaged server.
class profile::phabricator::migration (
    Stdlib::Fqdn        $src_host     = lookup('phabricator_active_server'),
    Array[Stdlib::Fqdn] $dst_hosts    = lookup('profile::phabricator::migration::dst_hosts'),
    Stdlib::Unixpath    $phabdir      = lookup('profile::phabricator::migration::phabdir'),
    String              $storage_user = lookup('profile::phabricator::migration::storage_user'),
    String              $deploy_user  = lookup('profile::phabricator::migration::deploy_user'),
) {

    # test db host access (T390034)
    include passwords::mysql::phorge_testdb
    $storage_pass = $passwords::mysql::phorge_testdb::admin_pass

    # setup scap user and symlink to binary before the first deploy and
    # before 'scap install-world' has installed scap itself (T357572)

    $scap_path = '/var/lib/scap/scap/bin'

    class { '::scap::user': }

    wmflib::dir::mkdir_p($scap_path, {
        owner   => 'scap',
        require => Class['scap::user'],
    })

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

    $sudo_env_keep = [
        'SCAP_REVS_DIR',
        'SCAP_FINAL_PATH',
        'SCAP_REV_PATH',
        'SCAP_CURRENT_REV_DIR',
        'SCAP_DONE_REV_DIR',
    ].join(' ')

    $sudo_scap_defaults = "Defaults:phab-deploy env_keep+=\"${sudo_env_keep}\"\n"

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

    scap::target { 'phabricator/deployment':
        deploy_user => 'phab-deploy',
        key_name    => 'phabricator',
        manage_user => true,
        require     => File['/usr/local/sbin/phab_deploy_finalize'],
        sudo_rules  => $sudo_rules,
    }

    file { '/etc/phabricator/script-vars':
        ensure  => present,
        content => template('phabricator/script-vars.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
    }

    file { '/srv/phab':
        ensure => link,
        target => '/srv/deployment/phabricator/deployment',
    }

    $fpm_config = {
        'date'                   => {
            'timezone' => 'UTC',
        },
        'opcache'                   => {
            'memory_consumption'      => 128,
            'interned_strings_buffer' => 16,
            'max_accelerated_files'   => 10000,
            'validate_timestamps'     => 0,
        },
        'max_execution_time'  => 30,
        'post_max_size'       => '10M',
        'track_errors'        => 'Off',
        'upload_max_filesize' => '10M',
    }

    $core_extensions =  [
        'curl',
        'gd',
        'gmp',
        'intl',
        'mbstring',
        'ldap',
    ]

    $php_version = wmflib::debian_php_version()

    # Install the runtime
    class { '::php':
        ensure         => present,
        versions       => [$php_version],
        sapis          => ['cli', 'fpm'],
        config_by_sapi => {
            'fpm' => $fpm_config,
        },
    }

    $core_extensions.each |$extension| {
        php::extension { $extension:
            versioned_packages => true,
            sapis              => ['cli', 'fpm'],
        }
    }

    class { '::php::fpm':
        ensure => present,
        config => {
            'emergency_restart_interval' => '60s',
            'process.priority'           => -19,
        },
    }

    # Extensions that require configuration.
    php::extension {
        default:
            sapis => ['cli', 'fpm'];
        'apcu':
            ;
        'mailparse':
            priority => 21;
        'mysqlnd':
            install_packages => false,
            priority         => 10;
        'xml':
            versioned_packages => true,
            priority           => 15;
        'mysqli':
            package_overrides => {"${php_version}" =>"php${php_version}-mysql"},;
    }

    $num_workers = max(floor($facts['processors']['count'] * 1.5), 8)
    # These numbers need to be positive integers
    $max_spare = ceiling($num_workers * 0.3)
    $min_spare = ceiling($num_workers * 0.1)
    php::fpm::pool { 'www':
        version => $php_version,
        config  => {
            'pm'                   => 'dynamic',
            'pm.max_spare_servers' => $max_spare,
            'pm.min_spare_servers' => $min_spare,
            'pm.start_servers'     => $min_spare,
            'pm.max_children'      => $num_workers,
        }
    }

    class { '::phabricator::phd::user': }

    if $facts['networking']['fqdn'] in $dst_hosts {

        file { '/srv/repos':
            ensure => directory,
        }

        file { '/srv/dumps':
            ensure => directory,
        }

        file { '/srv/homes':
            ensure => directory,
        }

        firewall::service { 'phabricator-migration-rsync':
            proto  => 'tcp',
            port   => [873],
            srange => [$src_host],
        }

        class { 'rsync::server': }

        rsync::server::module { 'phabricator-srv-repos':
            path        => '/srv/repos',
            read_only   => 'no',
            hosts_allow => $src_host,
        }

        rsync::server::module { 'phabricator-srv-dumps':
            path        => '/srv/dumps',
            read_only   => 'no',
            hosts_allow => $src_host,
        }
    }
}
