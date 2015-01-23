# Class: misc::statistics::cron_blog_pageviews
#
# Sets up daily cron jobs to run a script which
# groups blog pageviews by url and emails them
class misc::statistics::cron_blog_pageviews {
    include passwords::mysql::research

    $script          = '/usr/local/bin/blog.sh'
    $recipient_email = 'tbayer@wikimedia.org'

    $db_host         = 'db1047.eqiad.wmnet'
    $db_user         = $passwords::mysql::research::user
    $db_pass         = $passwords::mysql::research::pass

    file { $script:
        mode    => '0755',
        content => template('misc/email-blog-pageviews.erb'),
    }

    # Create a daily cron job to run the blog script
    # This requires that the $misc::statistics::user::username
    # user is installed on the source host.
    cron { 'blog_pageviews_email':
        command => $script,
        user    => $misc::statistics::user::username,
        hour    => 2,
        minute  => 0,
    }
}

# == Class misc::statistics::limn::data
# Sets up base directories and repositories
# for using the misc::statistics::limn::data::generate() define.
#
class misc::statistics::limn::data {
    include misc::statistics::base
    # include misc::statistics::stats_researchdb_password

    # Either '/a' or '/srv', depending on the server. :/
    $working_path      = $misc::statistics::base::working_path

    # Directory where the repository of the generate.py will be cloned.
    $source_dir        = "${working_path}/limn-mobile-data"

    # generate.py command to run in a cron.
    $command           = "${source_dir}/generate.py"

    # my.cnf credentials file. This is the file rendered by
    # misc::statistics::stats_researchdb_password.
    $mysql_credentials = '/etc/mysql/conf.d/stats-research-client.cnf'

    # cron job logs will be kept here
    $log_dir           = '/var/log/limn-data'

    # generate.py's repository
    $git_remote        = 'https://gerrit.wikimedia.org/r/p/analytics/limn-mobile-data.git'

    # public data directory.  Data will be synced from here to a public web host.
    $public_dir        = "${working_path}/limn-public-data"

    # Rsync generated data to stat1001 at http://datasets.wikimedia.org/limn-public-data/
    $rsync_to          = "stat1001.eqiad.wmnet::www/limn-public-data/"

    # user to own files and run cron job as (stats).
    $user              = $misc::statistics::user::username

    # This path is used in the limn-mobile-data config.
    # Symlink this until they change it.
    # https://github.com/wikimedia/analytics-limn-mobile-data/blob/2321a6a0976b1805e79fecd495cf12ed7c6565a0/mobile/config.yaml#L5
    file { "${working_path}/.my.cnf.research":
        ensure => 'link',
        target => $mysql_credentials,
    }

    # TODO:  This repository contains the generate.py script.
    # Other limn data repositories only have config and data
    # directories.  generate.py should be abstracted out into
    # a general purupose limn data generator.
    # For now, all limn data classes rely on this repository
    # and generate.py script to be present.
    if !defined(Git::Clone['analytics/limn-mobile-data']) {
        git::clone { 'analytics/limn-mobile-data':
            ensure    => 'latest',
            directory => $source_dir,
            origin    => $git_remote,
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # Make sure these are writeable by $user.
    file { [$log_dir, $public_dir]:
        ensure => 'directory',
        owner  => $user,
        group  => wikidev,
        mode   => '0775',
    }

    # Rsync anything generated in $public_dir to $rsync_to
    cron { "rsync_limn_public_data":
        command => "/usr/bin/rsync -rt ${public_dir}/* ${rsync_to}",
        user    => $user,
        minute  => 15,
    }
}



# == Define: misc::statistics::limn::data::generate
#
# Sets up daily cron jobs to run a script which
# generates csv datafiles and rsyncs those files
# to stat1001 so they can be served publicly.
#
# This requires that a repository with config to pass to generate.py
# exists at https://gerrit.wikimedia.org/r/p/analytics/limn-${title}-data.git.
#
# == Usage
#   misc::statistics::limn::data::generate { 'mobile': }
#   misc::statistics::limn::data::generate { 'flow': }
#   ...
#
define misc::statistics::limn::data::generate() {
    require misc::statistics::limn::data

    $user    = $misc::statistics::limn::data::user
    $command = $misc::statistics::limn::data::command

    # A repo at analytics/limn-${title}-data.git had better exist!
    $git_remote        = "https://gerrit.wikimedia.org/r/p/analytics/limn-${title}-data.git"

    # Directory at which to clone $git_remote
    $source_dir        = "${misc::statistics::limn::data::working_path}/limn-${title}-data"

    # config directory for this limn data generate job
    $config_dir        = "${$source_dir}/${title}/"

    # log file for the generate cron job
    $log               = "${misc::statistics::limn::data::log_dir}/limn-${title}-data.log"

    if !defined(Git::Clone["analytics/limn-${title}-data"]) {
        git::clone { "analytics/limn-${title}-data":
            ensure    => 'latest',
            directory => $source_dir,
            origin    => $git_remote,
            owner     => $user,
            require   => [User[$user]],
        }
    }

    # This will generate data into $public_dir/${title} (if configured correctly)
    cron { "generate_${title}_limn_public_data":
        command => "python ${command} ${config_dir} >> ${log} 2>&1",
        user    => $user,
        minute  => 0,
    }
}

# == Class misc::statistics::limn::data::jobs
# Uses the misc::statistics::limn::data::generate define
# to set up cron jobs to generate and sync particular data.
#
class misc::statistics::limn::data::jobs {
    misc::statistics::limn::data::generate { 'mobile': }
    misc::statistics::limn::data::generate { 'flow': }
    misc::statistics::limn::data::generate { 'edit': }
    misc::statistics::limn::data::generate { 'language': }
}

# == Class misc::statistics::geowiki::params
# Parameters for geowiki that get used outside this file
class misc::statistics::geowiki::params {
    include misc::statistics::base

    $base_path              = "${misc::statistics::base::working_path}/geowiki"
    $private_data_bare_path = "${base_path}/data-private-bare"
}

# == Class misc::statistics::geowiki
# Clones analytics/geowiki python scripts
class misc::statistics::geowiki {
    require misc::statistics::user,
        misc::statistics::geowiki::params

    $geowiki_user         = $misc::statistics::user::username
    $geowiki_base_path    = $misc::statistics::geowiki::params::base_path
    $geowiki_scripts_path = "${geowiki_base_path}/scripts"

    git::clone { 'geowiki-scripts':
        ensure    => 'latest',
        directory => $geowiki_scripts_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/geowiki.git',
        owner     => $geowiki_user,
        group     => $geowiki_user,
    }
}

# == Class misc::statistics::geowiki::mysql::conf::research
# Installs a mysql configuration file to connect to geowiki's
# research mysql instance
#
class misc::statistics::geowiki::mysql::conf::research {
    require misc::statistics::geowiki,
        passwords::mysql::research

    $geowiki_user = $misc::statistics::geowiki::geowiki_user
    $geowiki_base_path = $misc::statistics::geowiki::geowiki_base_path

    $research_mysql_user = $passwords::mysql::research::user
    $research_mysql_pass = $passwords::mysql::research::pass

    $conf_file = "${geowiki_base_path}/.research.my.cnf"
    file { $conf_file:
        owner   => $geowiki_user,
        group   => $geowiki_user,
        mode    => '0400',
        content => "
[client]
user=${research_mysql_user}
password=${research_mysql_pass}
host=s1-analytics-slave.eqiad.wmnet
# make_limn_files.py relies on a set default-character-set.
# This setting was in erosen's original MySQL configuration files, and without
# it, make_files_limpy.py fails with UnicodeDecodeError when writing out the csv files
default-character-set=utf8
",
    }
}

# == Class misc::statistics::geowiki::data::private_bare::sync
# Makes sure the geowiki's bare data-private repository is available.
#
class misc::statistics::geowiki::data::private_bare::sync {
    require misc::statistics::geowiki,
        misc::statistics::geowiki::params

    $geowiki_user                        = $misc::statistics::geowiki::geowiki_user
    $geowiki_base_path                   = $misc::statistics::geowiki::geowiki_base_path
    $geowiki_private_data_bare_path      = $misc::statistics::geowiki::params::private_data_bare_path
    $geowiki_private_data_bare_host      = 'stat1003'
    $geowiki_private_data_bare_host_fqdn = "${geowiki_private_data_bare_host}.eqiad.wmnet"

    file { $geowiki_private_data_bare_path:
        ensure => directory,
        owner  => $geowiki_user,
        group  => $geowiki_user,
        mode   => '0640',
    }

    # The bare repository lives on stat1003, so it's available there directly.
    # It only needs backup (as the repo is not living in gerrit)
    # Other hosts need to rsync it over
    if $::hostname == $geowiki_private_data_bare_host {
        include role::backup::host
        backup::set { 'a-geowiki-data-private-bare': }
    } else {
        cron { 'geowiki data-private bare sync':
            command => "/usr/bin/rsync -rt --delete rsync://${geowiki_private_data_bare_host_fqdn}${geowiki_private_data_bare_path}/ ${geowiki_private_data_bare_path}/",
            require => File[$geowiki_private_data_bare_path],
            user    => $geowiki_user,
            hour    => '17',
            minute  => '0',
        }
    }
}

# == Class misc::statistics::geowiki::data::private
# Makes sure the geowiki's data-private repository is available.
#
class misc::statistics::geowiki::data::private {
    require misc::statistics::geowiki,
        misc::statistics::geowiki::data::private_bare::sync

    $geowiki_user = $misc::statistics::geowiki::geowiki_user
    $geowiki_base_path = $misc::statistics::geowiki::geowiki_base_path
    $geowiki_private_data_path = "${geowiki_base_path}/data-private"
    $geowiki_private_data_bare_path = $misc::statistics::geowiki::data::private_bare::sync::geowiki_private_data_bare_path

    git::clone { 'geowiki-data-private':
        ensure    => 'latest',
        directory => $geowiki_private_data_path,
        origin    => "file://${geowiki_private_data_bare_path}",
        owner     => $geowiki_user,
        group     => 'www-data',
        mode      => 0750,
    }
}

# == Class misc::statistics::geowiki::jobs::data
# Installs a cron job to get recent editor data
# from the research slave databases and generate
# editor geocoding statistics, saved back into a db.
#
class misc::statistics::geowiki::jobs::data {
    require misc::statistics::geowiki,
        misc::statistics::geowiki::mysql::conf::research,
        passwords::mysql::globaldev,
        geoip
        # TODO: use require_packages
        # misc::statistics::packages::python,

    $geowiki_user = $misc::statistics::geowiki::geowiki_user
    $geowiki_base_path = $misc::statistics::geowiki::geowiki_base_path
    $geowiki_scripts_path = $misc::statistics::geowiki::geowiki_scripts_path

    $geowiki_mysql_research_conf_file = $misc::statistics::geowiki::mysql::conf::research::conf_file

    # install MySQL conf files for db acccess
    $globaldev_mysql_user = $passwords::mysql::globaldev::user
    $globaldev_mysql_pass = $passwords::mysql::globaldev::pass

    $geowiki_mysql_globaldev_conf_file = "${geowiki_base_path}/.globaldev.my.cnf"
    file { $geowiki_mysql_globaldev_conf_file:
        owner   => $geowiki_user,
        group   => $geowiki_user,
        mode    => '0400',
        content => "
[client]
user=${globaldev_mysql_user}
password=${globaldev_mysql_pass}
",
    }

    $geowiki_log_path = "${geowiki_base_path}/logs"
    file { $geowiki_log_path:
        ensure  => 'directory',
        owner   => $geowiki_user,
        group   => $geowiki_user,
    }

    # cron to run geowiki/process_data.py.
    # This will query the production slaves and
    # store results in the research staging database.
    # Logs will be kept $geowiki_log_path.
    cron { 'geowiki-process-data':
        minute  => 0,
        hour    => 12,
        user    => $geowiki_user,
        command => "/usr/bin/python ${geowiki_scripts_path}/geowiki/process_data.py -o ${geowiki_log_path} --wpfiles ${geowiki_scripts_path}/geowiki/data/all_ids.tsv --daily --start=`date --date='-2 day' +\\%Y-\\%m-\\%d` --end=`date --date='0 day' +\\%Y-\\%m-\\%d` --source_sql_cnf=${geowiki_mysql_globaldev_conf_file} --dest_sql_cnf=${geowiki_mysql_research_conf_file} >${geowiki_log_path}/process_data.py-cron-`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.stdout 2>${geowiki_log_path}/process_data.py-cron-`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.stderr",
        require => File[$geowiki_log_path],
    }
}

# == Class misc::statistics::geowiki::jobs::limn
# Installs a cron job to create limn files from the geocoded editor data.
class misc::statistics::geowiki::jobs::limn {
    require misc::statistics::geowiki,
        misc::statistics::geowiki::mysql::conf::research,
        misc::statistics::geowiki::data::private
        # misc::statistics::packages::python

    $geowiki_user = $misc::statistics::geowiki::geowiki_user
    $geowiki_base_path = $misc::statistics::geowiki::geowiki_base_path
    $geowiki_scripts_path = $misc::statistics::geowiki::geowiki_scripts_path
    $geowiki_public_data_path = "${geowiki_base_path}/data-public"
    $geowiki_private_data_path = $misc::statistics::geowiki::data::private::geowiki_private_data_path
    $geowiki_mysql_research_conf_file = $misc::statistics::geowiki::mysql::conf::research::conf_file

    git::clone { 'geowiki-data-public':
        ensure    => 'latest',
        directory => $geowiki_public_data_path,
        origin    => 'ssh://gerrit.wikimedia.org:29418/analytics/geowiki/data-public.git',
        owner     => $geowiki_user,
        group     => $geowiki_user,
    }

    # cron job to do the actual fetching from the database, computation of
    # the limn files, and pushing the limn files to the data repositories
    cron { 'geowiki-process-db-to-limn':
        minute  => 0,
        hour    => 15,
        user    => $geowiki_user,
        command => "${geowiki_scripts_path}/scripts/make_and_push_limn_files.sh --cron-mode --basedir_public=${geowiki_public_data_path} --basedir_private=${geowiki_private_data_path} --source_sql_cnf=${geowiki_mysql_research_conf_file}",
        require => [
            Git::Clone['geowiki-scripts'],
            Git::Clone['geowiki-data-public'],
            Git::Clone['geowiki-data-private'],
            File[$geowiki_mysql_research_conf_file],
        ],
    }
}

# == Class misc::statistics::geowiki::jobs::monitoring
# Checks if the geowiki files served throuh http://gp.wmflabs.org are
# up to date.
#
# Disabled for now due to restructuring of geowiki.
#
class misc::statistics::geowiki::jobs::monitoring {
    require misc::statistics::geowiki,
        passwords::geowiki

    $geowiki_user         = $misc::statistics::geowiki::geowiki_user
    $geowiki_base_path    = $misc::statistics::geowiki::geowiki_base_path
    $geowiki_scripts_path = $misc::statistics::geowiki::geowiki_scripts_path

    $geowiki_http_user    = $passwords::geowiki::user
    $geowiki_http_pass    = $passwords::geowiki::pass

    $geowiki_http_password_file = "${geowiki_base_path}/.http_password"

    file { $geowiki_http_password_file:
        owner   => $geowiki_user,
        group   => $geowiki_user,
        mode    => '0400',
        content => $geowiki_http_pass,
    }

    # cron job to fetch geowiki data via http://gp.wmflabs.org/ (public data)
    # and https://stats.wikimedia/geowiki-private (private data)
    # and checks that the files are up-to-date and within
    # meaningful ranges.
    cron { 'geowiki-monitoring':
        minute  => 30,
        hour    => 21,
        user    => $geowiki_user,
        command => "${geowiki_scripts_path}/scripts/check_web_page.sh --private-part-user ${geowiki_http_user} --private-part-password-file ${geowiki_http_password_file}",
    }
}
