# SPDX-License-Identifier: Apache-2.0
# @summary civicrm server setup for the community_civicrm site
#
# https://community-crm.wmcloud.org
#
# It runs on instance in the 'cloud VPS' project 'civicrm-prototype'.
#
# You can control this instance via https://horizon.wikimedia.org
# if you are a member or admin of the project.
#
# To report bugs use https://phabricator.wikimedia.org and
# tag a ticket with 'Fundraising-Backlog'.
#
# @param config_nonce a unique value to use in the site configuration dir
# @param hash_salt salt for one-time login links, cancel links, form tokens, etc.
# @param git_branch branch to check out of git for civicrm code
# @param site_name endpoint dns name for civicrm web interface
# @param db_host host of where the civicrm db is located
# @param db_user civicrm admin db user
# @param db_pass password for civicrm admin db user
# @param db_name database containing the civicrm tables
# @param file_root path for web site and vendor directories
# @param web_root path that holds web files for reference by the webserver

class community_civicrm (
    String $config_nonce,
    String $hash_salt,
    String $git_branch,
    Stdlib::Fqdn $site_name,
    Stdlib::Host $db_host = 'localhost',
    String $db_user = 'civi_admin',
    String $db_pass = 'FAKEFAKEFAKE',
    String $db_name = 'drupal',
    Stdlib::Unixpath $file_root = '/var/www/community_civicrm',
    Stdlib::Unixpath $web_root = "${file_root}/web",
){

    ensure_packages([
        'libapache2-mod-php',
        'php-bcmath',
        'php-curl',
        'php-gd',
        'php-intl',
        'php-mbstring',
        'php-mysql',
        'php-soap',
        'php-xml',
        'php-zip',
    ])

    $php_version = wmflib::debian_php_version()

    systemd::sysuser { 'civiadmin':
        additional_groups => [ 'www-data' ],
        home_dir          => '/usr/lib/community_civicrm',
    }

    file { '/srv/community_civicrm':
        ensure => directory,
        owner  => 'civiadmin',
        group  => 'civiadmin',
    }

    $civi_www_dirs = [
        '/var/www/community_civicrm/web/',
        '/var/www/community_civicrm/web/sites',
        '/var/www/community_civicrm/web/sites/default',
    ]

    file { $civi_www_dirs:
        ensure => 'directory',
        owner  => 'civiadmin',
        group  => 'www-data',
    }

    $www_admin_dirs = [
        '/var/www/community_civicrm/web/sites/default/files',
        "/var/www/community_civicrm/web/sites/default/files/config_${config_nonce}",
        "/var/www/community_civicrm/web/sites/default/files/config_${config_nonce}/sync",
        '/var/www/community_civicrm/web/sites/default/files/civicrm',
        '/var/www/community_civicrm/web/sites/default/files/civicrm/templates_c',
        '/var/www/community_civicrm/web/sites/default/files/css',
        '/var/www/community_civicrm/web/sites/default/files/js',
    ]

    file { $www_admin_dirs:
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
    }

    # add cv and drush bin dirs to PATH for all users
    file { '/etc/profile.d/community_civicrm_path.sh':
        ensure  => present,
        mode    => '0644',
        content => template('community_civicrm/civicrm/community_civicrm_path.sh.erb'),
    }

    # add civicrm settings file
    file { '/var/www/community_civicrm/web/sites/default/civicrm.settings.php':
        ensure  => present,
        owner   => 'civiadmin',
        group   => 'www-data',
        mode    => '0640',
        content => template('community_civicrm/civicrm/civicrm.settings.php.erb'),
    }

    # add drupal settings file
    file { '/var/www/community_civicrm/web/sites/default/settings.php':
        ensure  => present,
        owner   => 'civiadmin',
        group   => 'www-data',
        mode    => '0640',
        content => template('community_civicrm/civicrm/settings.php.erb'),
    }

    # add php settings specific for civicrm
    file { "/etc/php/${php_version}/apache2/conf.d/50-community_civicrm.ini":
        ensure  => file,
        content => wmflib::php_ini({
            # CiviCRM suggested php.ini values
            'memory_limit'        => '256M',
            'max_execution_time'  => '240',
            'max_input_time'      => '120',
            'post_max_size'       => '50M',
            'upload_max_filesize' => '50M',
            # Also don't show notice errors
            'error_reporting'     => 'E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE',
        }),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['apache2'],
    }

    # directory used by deploy-script to store backups
    file { '/usr/lib/community_civicrm/backup':
        ensure  => directory,
        owner   => 'civiadmin',
        group   => 'civiadmin',
        require => User['civiadmin'],
    }

    # deployment script that copies files in place after puppet git clones to /srv/
    file { '/usr/local/bin/community_civicrm-deploy':
        ensure => present,
        mode   => '0544',
        source => 'puppet:///modules/community_civicrm/deploy-community_civicrm.sh',
    }

    git::clone { 'repos/fundraising-tech/community-civicrm':
        ensure        => latest,
        directory     => '/srv/community_civicrm',
        branch        => $git_branch,
        owner         => 'civiadmin',
        group         => 'www-data',
        source        => 'gitlab',
        update_method => 'checkout',
    }

    # install a db on localhost
    class { 'community_civicrm::db':
        db_host     => $db_host,
        db_user     => $db_user,
        db_pass     => $db_pass,
        db_name     => $db_name,
        php_version => $php_version,
    }

    # run the regularly scheduled civi jobs
    # https://docs.civicrm.org/sysadmin/en/latest/setup/jobs/
    systemd::timer::job { 'community_civicrm-cv-job-run':
        ensure          => present,
        user            => 'www-data',
        description     => 'Run the jobs scheduled for civicrm',
        command         => "${file_root}/vendor/civicrm/cv/bin/cv api job.execute --user=civi_admin --cwd=${file_root}",
        logging_enabled => true,
        logfile_basedir => '/var/log/community_civicrm/',
        logfile_name    => 'cv-job-run.log',
        interval        => {'start' => 'OnCalendar', 'interval' => '*:0/5'},
    }


}
