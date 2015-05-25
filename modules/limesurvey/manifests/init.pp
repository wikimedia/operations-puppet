# = Class: limesurvey
#
# This class installs/configures/manages the LimeSurvey application.
#
# == Parameters:
# - $hostname: hostname for apache vhost
# - $deploy_dir: directory application is deployed to
# - $mysql_host: mysql database server
# - $mysql_db: mysql database
#
# == Sample usage:
#
#   class { 'limesurvey':
#   }
#
class limesurvey(
    $admin_email,
    $admin_pass,
    $mysql_pass,
    $mysql_user,
    $admin_user   = 'admin',
    $hostname     = 'limesurvey.wikimedia.org',
    $deploy_dir   = '/srv/limesurvey',
    $mysql_host   = 'localhost',
) {
    include ::apache::mod::headers
    include ::apache::mod::php5
    include ::apache::mod::rewrite

    require_package('php5-gd', 'php5-mysql')

    git::clone { 'limesurvey':
        ensure    => latest,
        directory => $deploy_dir,
        origin    => 'https://gerrit.wikimedia.org/r/p/operations/software/limesurvey.git',
        owner     => 'www-data',
        group     => 'www-data',
    }

    exec { 'install_limesurvey':
        command  => "/usr/bin/php console.php ${admin_user} ${admin_pass} admin ${admin_email}",
        cwd      => "${deploy_dir}/application/commands",
        creates  => "${deploy_dir}/installer/sql/create-mysql.sql",
        requires => Git::Clone['limesurvey'],
    }

    apache::site { 'limesurvey.wikimedia.org':
        content => template('limesurvey/apache.conf.erb'),
    }

    file { [ "${deploy_dir}/tmp", "${deploy_dir}/upload", "${deploy_dir}/application/config" ]:
        ensure  => directory,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0755',
        notify  => Service['apache2'],
        require => Git::Clone['limesurvey'],
    }
}
