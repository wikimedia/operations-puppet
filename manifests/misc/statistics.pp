# this file is for stat[0-9] statistics servers (per ezachte - RT 2162)

class misc::statistics::iptables-purges {
    require "iptables::tables"

    # The deny_all rule must always be purged, otherwise ACCEPTs can be placed below it
    iptables_purge_service{ "deny_all_redis": service => "redis" }

    # When removing or modifying a rule, place the old rule here, otherwise it won't
    # be purged, and will stay in the iptables forever
}

class misc::statistics::iptables-accepts {
    require "misc::statistics::iptables-purges"

    # Rememeber to place modified or removed rules into purges!
    iptables_add_service{ "redis_internal": source => "208.80.152.0/22", service => "redis", jump => "ACCEPT" }
}

class misc::statistics::iptables-drops {
    require "misc::statistics::iptables-accepts"

    # Deny by default
    iptables_add_service{ "deny_all_redis": service => "redis", jump => "DROP" }
}

class misc::statistics::iptables  {
    if $realm == "production" {
        # We use the following requirement chain:
        # iptables -> iptables::drops -> iptables::accepts -> iptables::accept-established -> iptables::purges
        #
        # This ensures proper ordering of the rules
        require "misc::statistics::iptables-drops"

        # This exec should always occur last in the requirement chain.
        iptables_add_exec{ $hostname: service => "statistics" }
    }

    # Labs has security groups, and as such, doesn't need firewall rules
}

class misc::statistics::user {
    $username = "stats"
    $homedir  = "/var/lib/$username"

    generic::systemuser { $username:
        name   => $username,
        home   => $homedir,
        groups => "wikidev",
        shell  => "/bin/bash",
    }

    # create a .gitconfig file for stats user
    file { "$homedir/.gitconfig":
        mode    => '0664',
        owner   => $username,
        content => "[user]\n\temail = otto@wikimedia.org\n\tname = Statistics User",
    }
}

class misc::statistics::base {
    system::role { "misc::statistics::base": description => "statistics server" }

    include misc::statistics::packages

    file {
        "/a":
            owner => root,
            group => wikidev,
            mode => '0775',
            ensure => directory,
            recurse => "false";
    }

    # Manually set a list of statistics servers.
    $servers = ["stat1.wikimedia.org", "stat1001.wikimedia.org", "stat1002.eqiad.wmnet", "analytics1027.eqiad.wmnet"]

    # set up rsync modules for copying files
    # on statistic servers in /a
    class { "misc::statistics::rsyncd": hosts_allow => $servers }
}


class misc::statistics::packages {
    package { [
        'mc',
        'zip',
        'p7zip',
        'p7zip-full',
        'subversion',
        'mercurial',
        'tofrodos',
        'git-review',
        'imagemagick',
    ]:
        ensure => latest;
    }

    include misc::statistics::packages::python
}


# Packages needed for various python stuffs
# on statistics servers.
class misc::statistics::packages::python {
    package { [
        "python-geoip",
        "libapache2-mod-python",
        "python-django",
        "python-mysqldb",
        "python-yaml",
        "python-dateutil",
        "python-numpy",
        "python-scipy",
    ]:
        ensure => 'installed',
    }
}

# Installs java.
class misc::statistics::packages::java {
    package { 'openjdk-7-jdk': }
}

# Mounts /data from dataset2 server.
# xmldumps and other misc files needed
# for generating statistics are here.
class misc::statistics::dataset_mount {
    # need this for NFS mounts.
    include nfs::common

    file { "/mnt/data": ensure => directory }

    mount { "/mnt/data":
        device => "208.80.152.185:/data",
        fstype => "nfs",
        options => "ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.152.185",
        atboot => true,
        require => [File['/mnt/data'], Class["nfs::common"]],
        ensure => mounted,
    }
}


# clones mediawiki core at /a/mediawiki/core
# and ensures that it is at the latest revision.
# RT 2162
class misc::statistics::mediawiki {
    require mediawiki::users::mwdeploy

    $statistics_mediawiki_directory = "/a/mediawiki/core"

    git::clone { "statistics_mediawiki":
        directory => $statistics_mediawiki_directory,
        origin    => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git",
        ensure    => 'latest',
        owner     => 'mwdeploy',
        group     => 'wikidev',
    }
}

# wikistats configuration for generating
# stats.wikimedia.org data.
#
# TODO: puppetize clone of wikistats?
class misc::statistics::wikistats {
    # Perl packages needed for wikistats
    package { [
        'libjson-xs-perl',
        'libtemplate-perl',
        'libnet-patricia-perl',
        'libregexp-assemble-perl',
    ]:
        ensure => 'installed',
    }
    # this cron uses pigz to unzip squid archive files in parallel
    package { 'pigz':
        ensure => 'installed'
    }

    # generates the new mobile pageviews report
    # and syncs the file PageViewsPerMonthAll.csv to stat1002
    cron { 'new mobile pageviews report':
        command  => '/bin/bash /a/wikistats_git/pageviews_reports/bin/stat1-cron-script.sh',
        user     => 'stats',
        monthday => 1,
        hour     => 7,
        minute   => 20,
    }
}

# RT-2163
class misc::statistics::plotting {

    package { [
            "ploticus",
            "libploticus0",
            "r-base",
            "r-cran-rmysql",
            "libcairo2",
            "libcairo2-dev",
            "libxt-dev"
        ]:
        ensure => installed;
    }
}


class misc::statistics::webserver {
    include webserver::apache

    # make sure /var/log/apache2 is readable by wikidevs for debugging.
    # This won't make the actual log files readable, only the directory.
    # Individual log files can be created and made readable by
    # classes that manage individual sites.
    file { '/var/log/apache2':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0750',
        require => Class['webserver::apache'],
    }

    webserver::apache::module { ['rewrite', 'proxy', 'proxy_http']:
        require => Class['webserver::apache']
    }
}

# reportcard.wikimedia.org
class misc::statistics::sites::reportcard {
    require misc::statistics::webserver
    misc::limn::instance { 'reportcard': }
}

# rsync sanitized data that has been readied for public consumption to a
# web server.
class misc::statistics::public_datasets {
    file { '/var/www/public-datasets':
        ensure => directory,
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # rsync from stat1:/a/public-datasets to /var/www/public-datasets/
    cron { 'rsync public datasets':
        command => '/usr/bin/rsync -rt --delete stat1.wikimedia.org::a/public-datasets/* /var/www/public-datasets/',
        require => File['/var/www/public-datasets'],
        user    => 'root',
        minute  => '*/30',
    }
}

# stats.wikimedia.org
class misc::statistics::sites::stats {
    $site_name = "stats.wikimedia.org"
    $docroot = "/srv/$site_name/htdocs"

    # add htpasswd file for stats.wikimedia.org
    file { "/etc/apache2/htpasswd.stats":
        owner   => "root",
        group   => "root",
        mode    => '0644',
        source  => "puppet:///private/apache/htpasswd.stats",
    }

  install_certificate{ $site_name: }

  file {
    '/etc/apache2/sites-available/stats.wikimedia.org':
        ensure => present,
        mode => '0444',
        owner => root,
        group => root,
        content => template('apache/sites/stats.wikimedia.org.erb');
    '/etc/apache2/ports.conf':
        ensure  => present,
        mode    => '0644',
        owner   => root,
        group   => root,
        source  => 'puppet:///files/apache/ports.conf.ssl';
    }

  apache_site { 'statswikimedia': name => 'stats.wikimedia.org' }

}

# community-analytics.wikimedia.org
class misc::statistics::sites::community_analytics {
    $site_name = "community-analytics.wikimedia.org"
    $docroot = "/srv/org.wikimedia.community-analytics/community-analytics/web_interface"

    # org.wikimedia.community-analytics is kinda big,
    # it really lives on /a.
    # Symlink /srv/a/org.wikimedia.community-analytics to it.
    file { "/srv/org.wikimedia.community-analytics":
        ensure => "/a/srv/org.wikimedia.community-analytics"
    }

    webserver::apache::site { $site_name:
        require => [Class["webserver::apache"], Class["misc::statistics::packages::python"]],
        docroot => $docroot,
        server_admin => "noc@wikimedia.org",
        custom => [
            "SetEnv MPLCONFIGDIR /srv/org.wikimedia.community-analytics/mplconfigdir",

    "<Location \"/\">
        SetHandler python-program
        PythonHandler django.core.handlers.modpython
        SetEnv DJANGO_SETTINGS_MODULE web_interface.settings
        PythonOption django.root /community-analytics/web_interface
        PythonDebug On
        PythonPath \"['/srv/org.wikimedia.community-analytics/community-analytics'] + sys.path\"
    </Location>",

    "<Location \"/media\">
        SetHandler None
    </Location>",

    "<Location \"/static\">
        SetHandler None
    </Location>",

    "<LocationMatch \"\\.(jpg|gif|png)$\">
        SetHandler None
    </LocationMatch>",
    ],
    }
}

# metrics-api.wikimedia.org
# See: http://stat1.wikimedia.org/rfaulk/pydocs/_build/env.html
# for more info on how and why.
#
# TODO: Make this a module.
#
class misc::statistics::sites::metrics {
    require misc::statistics::user,
        misc::statistics::packages::python,
        passwords::mysql::research,
        passwords::mysql::research_prod,
        passwords::mysql::metrics,
        passwords::e3::metrics

    $site_name        = "metrics.wikimedia.org"
    $document_root    = "/srv/org.wikimedia.metrics"

    $e3_home          = "/a/e3"
    $e3_analysis_path = "$e3_home/E3Analysis/"
    $metrics_user     = $misc::statistics::user::username

    $secret_key       = $passwords::e3::metrics::secret_key

    # connetions will be rendered into settings.py.
    $mysql_connections = {
        'slave'   => {
            'user'   =>  $passwords::mysql::metrics::user,
            'passwd' =>  $passwords::mysql::metrics::pass,
            'host'   =>  'db1047.eqiad.wmnet',
            'port'   =>  3306,
            'db'     =>  'prod',
        },
        'cohorts' =>  {
            'user'   =>  $passwords::mysql::research_prod::user,
            'passwd' =>  $passwords::mysql::research_prod::pass,
            'host'   =>  'db1047.eqiad.wmnet',
            'port'   =>  3306,
            'db'     =>  'prod',
        },
        's1'      =>  {
            'user'   =>   $passwords::mysql::research::user,
            'passwd' =>   $passwords::mysql::research::pass,
            'host'   =>  's1-analytics-slave.eqiad.wmnet',
            'port'   =>   3306,
        },
        's2'      =>  {
            'user'   =>   $passwords::mysql::research::user,
            'passwd' =>   $passwords::mysql::research::pass,
            'host'   =>  's2-analytics-slave.eqiad.wmnet',
            'port'   =>  3306,
        },
        's3'      =>  {
            'user'   =>   $passwords::mysql::research::user,
            'passwd' =>   $passwords::mysql::research::pass,
            'host'   =>  's3-analytics-slave.eqiad.wmnet',
            'port'   =>  3306,
        },
        's4'      =>  {
            'user'   =>   $passwords::mysql::research::user,
            'passwd' =>   $passwords::mysql::research::pass,
            'host'   =>  's4-analytics-slave.eqiad.wmnet',
            'port'   =>  3306,
        },
        's5'      =>  {
            'user'   =>   $passwords::mysql::research::user,
            'passwd' =>   $passwords::mysql::research::pass,
            'host'   =>  's5-analytics-slave.eqiad.wmnet',
            'port'   =>  3306,
        },
                's6'      =>  {
                        'user'   =>   $passwords::mysql::research::user,
                        'passwd' =>   $passwords::mysql::research::pass,
                        'host'   =>  's6-analytics-slave.eqiad.wmnet',
                        'port'   =>  3306,
                },
                's7'      =>  {
                        'user'   =>   $passwords::mysql::research::user,
                        'passwd' =>   $passwords::mysql::research::pass,
                        'host'   =>  's7-analytics-slave.eqiad.wmnet',
                        'port'   =>  3306,
                },
    }

    package { ["python-flask", "python-flask-login"]:
        ensure => "installed",
    }

    file { [$e3_home, $document_root]:
        ensure => "directory",
        owner  => $misc::statistics::user::username,
        group  => "wikidev",
        mode   => '0775',
    }

    # install a .htpasswd file for E3
    file { "$e3_home/.htpasswd":
        content  => $passwords::e3::metrics::htpasswd_content,
        owner    => $metrics_user,
        group    => "wikidev",
        mode     => '0664',
    }

    # clone the E3 Analysis repository
    git::clone { "E3Analysis":
        directory => $e3_analysis_path,
        origin    => "https://gerrit.wikimedia.org/r/p/analytics/user-metrics.git",
        owner     => $metrics_user,
        group     => "wikidev",
        require   => [Package["python-flask"], File[$e3_home], Class["misc::statistics::user"], Class["misc::statistics::packages::python"]],
        ensure    => "latest",
    }

    # Need settings.py to configure metrics-api python application
    # Make this only readable by stats user; it has db passwords in it.
    file { "$e3_analysis_path/user_metrics/config/settings.py":
        content => template("misc/e3-metrics.settings.py.erb"),
        owner   => $metrics_user,
        group   => "root",
        mode    => '0640',
        require => Git::Clone["E3Analysis"],
    }

    # symlink the api.wsgi app loader python script.
    # api.wsgi loads 'src.api' as a module :/
    file { "$document_root/api.wsgi":
        ensure  => "$e3_analysis_path/user_metrics/api/api.wsgi",
        require => Git::Clone["E3Analysis"],
    }

    include webserver::apache
    webserver::apache::module { "wsgi": }
    webserver::apache::module { "alias": }
    webserver::apache::module { "ssl": }

    # install metrics.wikimedia.org SSL certificate
  install_certificate{ $site_name: }

    # Set up the Python WSGI VirtualHost
    file { "/etc/apache2/sites-available/$site_name":
        content => template("apache/sites/${site_name}.erb"),
        require =>  [File[$document_root], File["$e3_home/.htpasswd"], Class["webserver::apache"], Webserver::Apache::Module["wsgi"], Webserver::Apache::Module['alias'], Webserver::Apache::Module['ssl']],
        notify  => Class['webserver::apache::service'],
    }
    file { "/etc/apache2/sites-enabled/$site_name":
        ensure  => link,
        target  => "/etc/apache2/sites-available/${site_name}",
        require => File["/etc/apache2/sites-available/${site_name}"],
        notify  => Class['webserver::apache::service'],
    }

    # make access and error log for metrics-api readable by wikidev group
    file { ["/var/log/apache2/access.metrics.log", "/var/log/apache2/error.metrics.log"]:
        group   => "wikidev",
        require => File["/etc/apache2/sites-enabled/$site_name"],
    }
}

# installs MonogDB on stat1
class misc::statistics::db::mongo {
    class { "mongodb":
        dbpath    => "/a/mongodb",
    }
}

# == Class misc::statistics::gerrit_stats
#
# Installs diederik's gerrit-stats python
# scripts, and sets a cron job to run it and
# to commit and push generated data into
# a repository.
#
class misc::statistics::gerrit_stats {
    $gerrit_stats_repo_url      = "https://gerrit.wikimedia.org/r/p/analytics/gerrit-stats.git"
    $gerrit_stats_data_repo_url = "ssh://stats@gerrit.wikimedia.org:29418/analytics/gerrit-stats/data.git"
    $gerrit_stats_base          = "/a/gerrit-stats"
    $gerrit_stats_path          = "$gerrit_stats_base/gerrit-stats"
    $gerrit_stats_data_path     = "$gerrit_stats_base/data"


    # use the stats user
    $gerrit_stats_user          = $misc::statistics::user::username
    $gerrit_stats_user_home     = $misc::statistics::user::homedir

    file { $gerrit_stats_base:
        owner  => $gerrit_stats_user,
        group  => "wikidev",
        mode   => '0775',
        ensure => "directory",
    }



    # Clone the gerrit-stats and gerrit-stats/data
    # repositories into subdirs of $gerrit_stats_path.
    # This requires that the $gerrit_stats_user
    # has an ssh key that is allowed to clone
    # from git.less.ly.

    git::clone { "gerrit-stats":
        directory => $gerrit_stats_path,
        origin    => $gerrit_stats_repo_url,
        owner     => $gerrit_stats_user,
        require   => [User[$gerrit_stats_user], Class["misc::statistics::packages::python"]],
        ensure    => "latest",
    }

    git::clone { "gerrit-stats/data":
        directory => $gerrit_stats_data_path,
        origin    => $gerrit_stats_data_repo_url,
        owner     => $gerrit_stats_user,
        require   => User[$gerrit_stats_user],
        ensure    => "latest",
    }

    # Make sure ~/.my.cnf is only readable by stats user.
    # The gerrit stats script requires this file to
    # connect to gerrit MySQL database.
    file { "$gerrit_stats_user_home/.my.cnf":
        mode  => '0600',
        owner => stats,
        group => stats,
    }

    # Run a cron job from the $gerrit_stats_path.
    # This will create a $gerrit_stats_path/data
    # directory containing stats about gerrit.
    #
    # Note: gerrit-stats requires mysql access to
    # the gerrit stats database.  The mysql user creds
    # are configured in /home/$gerrit_stats_user/.my.cnf,
    # which is not puppetized in order to keep pw private.
    #
    # Once gerrit-stats has run, the newly generated
    # data in $gerrit_stats_path/data will be commited
    # and pushed to the gerrit-stats/data repository.
    cron { "gerrit-stats-daily":
        ensure  => absent,
        command => "/usr/bin/python $gerrit_stats_path/gerritstats/stats.py --dataset $gerrit_stats_data_path --toolkit dygraphs --settings /a/gerrit-stats/gerrit-stats/gerritstats/settings.yaml >> $gerrit_stats_base/gerrit-stats.log && (cd $gerrit_stats_data_path && git add . && git commit -q -m \"Updating gerrit-stats data after gerrit-stats run at $(date)\" && git push -q)",
        user    => $gerrit_stats_user,
        hour    => '23',
        minute  => '59',
        require => [Git::Clone["gerrit-stats"], Git::Clone["gerrit-stats/data"], File["$gerrit_stats_user_home/.my.cnf"]],
    }
}


# Sets up rsyncd and common modules
# for statistic servers.  Currently
# this is read/write between statistic
# servers in /a.
#
# Parameters:
#   hosts_allow - array.  Hosts to grant rsync access.
class misc::statistics::rsyncd($hosts_allow = undef) {
    # this uses modules/rsync to
    # set up an rsync daemon service
    include rsync::server

    # Set up an rsync module
    # (in /etc/rsync.conf) for /a.
    rsync::server::module { "a":
        path        => "/a",
        read_only   => "no",
        list        => "yes",
        hosts_allow => $hosts_allow,
    }

    # Set up an rsync module
    # (in /etc/rsync.conf) for /var/www.
    # This will allow $hosts_allow to host public data files
    # from the default Apache VirtualHost.
    rsync::server::module { "www":
        path        => "/var/www",
        read_only   => "no",
        list        => "yes",
        hosts_allow => $hosts_allow,
    }
}



# Class: misc::statistics::rsync::jobs::webrequest
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class misc::statistics::rsync::jobs::webrequest {

    # Make sure destination directories exist.
    # Too bad I can't do this with recurse => true.
    # See: https://projects.puppetlabs.com/issues/86
    # for a much too long discussion on why I can't.
    file { [
        "/a/squid",
        "/a/squid/archive",
        "/a/aft",
        "/a/aft/archive",
        "/a/public-datasets",
    ]:
        ensure  => directory,
        owner   => "stats",
        group   => "wikidev",
        mode    => '0775',
    }

    # wikipedia zero logs from oxygen
    misc::statistics::rsync_job { "wikipedia_zero":
        source      => "oxygen.wikimedia.org::udp2log/webrequest/archive/zero*.gz",
        destination => "/a/squid/archive/zero",
    }

    # API logs from emery
    misc::statistics::rsync_job { "api":
        source      => "emery.wikimedia.org::udp2log/webrequest/archive/api-usage*.gz",
        destination => "/a/squid/archive/api",
    }

    # teahouse logs from emery
    misc::statistics::rsync_job { "teahouse":
        source      => "emery.wikimedia.org::udp2log/webrequest/archive/teahouse*.gz",
        destination => "/a/squid/archive/teahouse",
    }

    # arabic banner logs from emery
    misc::statistics::rsync_job { "arabic_banner":
        source      => "emery.wikimedia.org::udp2log/webrequest/archive/arabic-banner*.gz",
        destination => "/a/squid/archive/arabic-banner",
    }

    # sampled-1000 logs from emery
    misc::statistics::rsync_job { "sampled_1000":
        source      => "emery.wikimedia.org::udp2log/webrequest/archive/sampled-1000*.gz",
        destination => "/a/squid/archive/sampled",
    }

    # edit logs from oxygen
    misc::statistics::rsync_job { "edits":
        source      => "oxygen.wikimedia.org::udp2log/webrequest/archive/edits*.gz",
        destination => "/a/squid/archive/edits",
    }

    # mobile logs from oxygen
    misc::statistics::rsync_job { "mobile":
        source      => "oxygen.wikimedia.org::udp2log/webrequest/archive/mobile*.gz",
        destination => "/a/squid/archive/mobile",
    }
}

# Class: misc::statistics::rsync::jobs::eventlogging
#

# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class misc::statistics::rsync::jobs::eventlogging {
    file { '/a/eventlogging':
        ensure  => directory,
        owner   => "stats",
        group   => "wikidev",
        mode    => '0775',
    }

    # eventlogging logs from vanadium
    misc::statistics::rsync_job { "eventlogging":
        source      => "vanadium.eqiad.wmnet::eventlogging/archive/*.gz",
        destination => "/a/eventlogging/archive",
    }

    $sets = [ 'a-eventlogging', 'home', ]
    include backup::host
    backup::set { $sets : }
}

# Define: misc::statistics::rsync_job
#
# Sets up a daily cron job to rsync from $source to $destination
# as the $misc::statistics::user::username user.  This requires
# that the $misc::statistics::user::username user is installed
# on both $source and $destination hosts.
#
# Parameters:
#    source      - rsync source argument (including hostname)
#    destination - rsync destination argument
#
define misc::statistics::rsync_job($source, $destination) {
    require misc::statistics::user

    # ensure that the destination directory exists
    file { $destination:
        ensure  => "directory",
        owner   => $misc::statistics::user::username,
        group   => "wikidev",
        mode    => '0775',
    }

    # Create a daily cron job to rsync $source to $destination.
    # This requires that the $misc::statistics::user::username
    # user is installed on the source host.
    cron { "rsync_${name}_logs":
        command => "/usr/bin/rsync -rt $source $destination/",
        user    => $misc::statistics::user::username,
        hour    => 8,
        minute  => 0,
    }
}


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


# Class: misc::statistics::limn::mobile_data_sync
#
# Sets up daily cron jobs to run a script which
# generates csv datafiles from mobile apps statistics
# then rsyncs those files to stat1001 so they can be served publicly
class misc::statistics::limn::mobile_data_sync {
    include passwords::mysql::research

    $source_dir        = "/a/limn-mobile-data"
    $command           = "$source_dir/generate.py"
    $config            = "$source_dir/mobile/"
    $mysql_credentials = "/a/.my.cnf.research"
    $rsync_from        = "/a/limn-public-data"
    $output            = "$rsync_from/mobile/datafiles"
    $gerrit_repo       = "https://gerrit.wikimedia.org/r/p/analytics/limn-mobile-data.git"
    $user              = $misc::statistics::user::username

    $db_user           = $passwords::mysql::research::user
    $db_pass           = $passwords::mysql::research::pass

    git::clone { "analytics/limn-mobile-data":
        directory => $source_dir,
        origin    => $gerrit_repo,
        owner     => $user,
        require   => [User[$user]],
        ensure    => latest,
    }

    file { $mysql_credentials:
        owner   => $user,
        group   => $user,
        mode    => '0600',
        content => template("misc/mysql-config-research.erb"),
    }

    file { $output:
        owner  => $user,
        group  => wikidev,
        mode   => '0775',
        ensure => directory,
    }

    cron { "rsync_mobile_apps_stats":
        command => "python $command $config && /usr/bin/rsync -rt $rsync_from/* stat1001.wikimedia.org::www/limn-public-data/",
        user    => $user,
        minute  => 0,
    }
}


# == Class misc::statistics::geowiki
# Clones analytics/geowiki python scripts
class misc::statistics::geowiki {
    require misc::statistics::user

    $geowiki_user = $misc::statistics::user::username
    $geowiki_base_path = '/a/geowiki'
    $geowiki_scripts_path = "${geowiki_base_path}"

    git::clone { 'geowiki':
        directory => $geowiki_scripts_path,
        origin    => "https://gerrit.wikimedia.org/r/p/analytics/geowiki.git",
        ensure    => 'latest',
        owner     => $geowiki_user,
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

# == Class misc::statistics::geowiki::jobs::data
# Installs a cron job to get recent editor data
# from the research slave databases and generate
# editor geocoding statistics, saved back into a db.
#
class misc::statistics::geowiki::jobs::data {
    require misc::statistics::geowiki,
        misc::statistics::geowiki::mysql::conf::research,
        passwords::mysql::globaldev,
        misc::statistics::packages::python,
        geoip

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

    $geowiki_backups_path = "${geowiki_base_path}/geowiki-backup-data"
    file { $geowiki_backups_path:
        ensure  => 'directory',
        owner   => $geowiki_user,
        group   => $geowiki_user,
    }

    # cron to run geowiki/process_data.py.
    # This will query the production slaves and
    # store results in the research staging database.
    # Backup files will be kept $geowiki_backups_path.
    cron { 'geowiki-process-data':
        minute  => 0,
        hour    => 12,
        user    => $geowiki_user,
        command => "/usr/bin/python ${geowiki_scripts_path}/geowiki/process_data.py -o ${$geowiki_backups_path} --wpfiles ${geowiki_scripts_path}/geowiki/data/all_ids.tsv --daily --start=`date --date='-2 day' +\\%Y-\\%m-\\%d` --end=`date --date='0 day' +\\%Y-\\%m-\\%d` --source_sql_cnf=${geowiki_mysql_globaldev_conf_file} --dest_sql_cnf=${geowiki_mysql_research_conf_file}",
        require => File[$geowiki_backups_path],
    }
}

# == Class misc::statistics::geowiki::jobs::limn
# Installs a cron job to create limn files from the geocoded editor data.
#
# Temporarily turned off reboot the geowiki repository.
class misc::statistics::geowiki::jobs::limn {
    require misc::statistics::geowiki,
        misc::statistics::geowiki::mysql::conf::research,
        misc::statistics::packages::python

    $geowiki_user = $misc::statistics::geowiki::geowiki_user
    $geowiki_scripts_path = $misc::statistics::geowiki::geowiki_scripts_path
    $geowiki_data_path = '/a/geowiki-data'
    $geowiki_mysql_research_conf_file = $misc::statistics::geowiki::mysql::conf::research::conf_file

    git::clone { 'geowiki-data':
        directory => $geowiki_data_path,
        origin    => "ssh://gerrit.wikimedia.org:29418/analytics/geowiki-data.git",
        # As geowiki-data currently does not exist in gerrit, requiring the
        # latest version would break puppet's the dependecy chain. So we'll not
        # 'ensure => latest' until the repo comes back in gerrit.
        ensure    => 'present',
        owner     => $geowiki_user,
    }

    # cron job to do the actual fetching from the database, computation of
    # the limn files, and pushing the limn files to the geowiki-data
    # repository.
    cron { 'geowiki-process-db-to-limn':
        minute  => 0,
        hour    => 15,
        user    => $geowiki_user,
        command => "${geowiki_scripts_path}/scripts/make_and_push_limn_files.sh --cron-mode --basedir=${geowiki_data_path} --source_sql_cnf=${geowiki_mysql_research_conf_file}",
        require => [
            Git::Clone['geowiki'],
            Git::Clone['geowiki-data'],
            File[$geowiki_mysql_research_conf_file],
        ],
        ensure  => absent,
    }
}

# == Class misc::statistics::geowiki::jobs::monitoring
# Checks if the geowiki files served throuh http://gp.wmflabs.org are
# up to date.
#
# Disabled for now due to restructuring of geowiki.
#
class misc::statistics::geowiki::jobs::monitoring {
    require misc::statistics::geowiki

    $geowiki_user = $misc::statistics::geowiki::geowiki_user
    $geowiki_scripts_path = $misc::statistics::geowiki::geowiki_scripts_path

    # cron job to fetch geowiki data via http://gp.wmflabs.org/
    # and checks that the files are up-to-date and within
    # meaningful ranges.
    cron { 'geowiki-monitoring':
        minute  => 30,
        hour    => 21,
        user    => $geowiki_user,
        command => "${geowiki_scripts_path}/scripts/check_web_page.sh",
        # Disabled for now due to restructuring of geowiki
        ensure  => absent,
    }
}
