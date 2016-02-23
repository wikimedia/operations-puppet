# phabricator instance on wmflabs at phab-0[1-9].wmflabs.org
class role::phabricator::labs {

    # pass not sensitive but has to match phab and db
    $mysqlpass = 'labspass'
    $current_tag = 'release/2016-02-18/1'
    class { '::phabricator':
        git_tag       => $current_tag,
        lock_file     => '/var/run/phab_repo_lock',
        sprint_tag    => 'release/2016-02-18/1',
        security_tag  => 'release/2016-02-18/2',
        libraries     => ['/srv/phab/libext/Sprint/src',
                          '/srv/phab/libext/security/src'],
        extension_tag => 'release/2016-02-18/1',
        extensions    => [ 'MediaWikiUserpageCustomField.php',
                              'LDAPUserpageCustomField.php',
                              'PhabricatorMediaWikiAuthProvider.php',
                              'PhutilMediaWikiAuthAdapter.php'],
        settings      => {
            'darkconsole.enabled'             => true,
            'phabricator.base-uri'            => "https://${::hostname}.wmflabs.org",
            'mysql.pass'                      => $mysqlpass,
            'auth.require-email-verification' => false,
            'metamta.mail-adapter'            => 'PhabricatorMailImplementationTestAdapter',
            'repository.default-local-path'   => '/srv/phab/repos',
            'config.ignore-issues'            => '{
                                                      "security.security.alternate-file-domain": true
                                                  }',
        },
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
