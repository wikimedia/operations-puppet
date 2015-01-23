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
        user    => $::statistics::user::username,
        hour    => 2,
        minute  => 0,
    }
}


# == Class misc::statistics::geowiki::params
# Parameters for geowiki that get used outside this file
class misc::statistics::geowiki::params {
    $base_path              = '/srv/geowiki'
    $private_data_bare_path = "${base_path}/data-private-bare"
}

# == Class misc::statistics::geowiki
# Clones analytics/geowiki python scripts
class misc::statistics::geowiki {
    require ::statistics::user,
        misc::statistics::geowiki::params

    $geowiki_user         = $::statistics::user::username
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
