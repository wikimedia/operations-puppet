# phabricator instance on wmflabs at phab-0[1-9].wmflabs.org

class role::phabricator::labs(
        $settings,
) {

    $conf_files = {
        'www' => {
            'environment'       => 'www',
            'owner'             => 'root',
            'group'             => 'www-data',
            'phab_settings'     => {
                'mysql.user'        => 'root',
                'mysql.pass'        => 'labspass',
            }
        },
        'phd' => {
            'environment'       => 'phd',
            'owner'             => 'root',
            'group'             => 'phd',
            'phab_settings'     => {
                'mysql.user'        => 'root',
                'mysql.pass'        => 'labspass',
            }
        },
    }

    $role_settings = {
        'darkconsole.enabled'             => true,
        'phabricator.base-uri'            => "https://${::hostname}.wmflabs.org",
        'mysql.pass'                      => $mysqlpass,
        'auth.require-email-verification' => false,
        'metamta.mail-adapter'            => 'PhabricatorMailImplementationTestAdapter',
        'repository.default-local-path'   => '/srv/repos',
        'phd.taskmasters'                 => 1,
        'config.ignore-issues'            => '{
                                                  "security.security.alternate-file-domain": true
                                              }',
    }

    $phab_settings = merge($settings, $role_settings)
    # pass not sensitive but has to match phab and db
    $mysqlpass = 'labspass'
    $phab_root_dir = '/srv/phab'

    class { '::phabricator':
        deploy_target => 'phabricator/deployment',
        phabdir       => $phab_root_dir,
        libraries     => ["${phab_root_dir}/libext/Sprint/src",
                          "${phab_root_dir}/libext/security/src",
                          "${phab_root_dir}/libext/misc/"],
        settings      => $phab_settings,
        conf_files    => $conf_files,
    }

    package { 'mysql-server': ensure => present }

    class { 'mysql::config':
        root_password => $mysqlpass,
        sql_mode      => 'STRICT_ALL_TABLES',
        restart       => true,
        require       => Package['mysql-server'],
    }

    service { 'mysql':
        ensure     => running,
        hasrestart => true,
        hasstatus  => true,
        require    => Package['mysql-server'],
    }
}
