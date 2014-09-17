class misc::statistics::user {
    $username = 'stats'
    $homedir  = "/var/lib/${username}"

    group { $username:
        ensure => present,
        name   => $username,
        system => true,
    }

    user { $username:
        home       => $homedir,
        groups     => ['wikidev'],
        shell      => '/bin/bash',
        managehome => true,
        system     => true
    }

    # create a .gitconfig file for stats user
    file { "${homedir}/.gitconfig":
        mode    => '0664',
        owner   => $username,
        content => "[user]\n\temail = otto@wikimedia.org\n\tname = Statistics User",
    }
}

class misc::statistics::base {
    system::role { 'misc::statistics::base':
        description => 'statistics server',
    }

    include misc::statistics::packages

    # we are attempting to stop using /a and to start using
    # /srv instead.  stat1001 and stat1002 still use
    # /a by default.  # stat1003 uses /srv.
    $working_path = $::hostname ? {
        'stat1003' => '/srv',
        default    => '/a',
    }
    file { $working_path:
        ensure  => 'directory',
        owner   => 'root',
        group   => 'wikidev',
        mode    => '0775',
    }

    if $working_path == '/srv' {
        # symlink /a to /srv for backwards compatibility
        file { '/a':
            ensure => 'link',
            target => '/srv',
        }
    }

    # Manually set a list of statistics servers.
    $servers = [
        'stat1001.wikimedia.org',
        'stat1002.eqiad.wmnet',
        'stat1003.wikimedia.org',
        'analytics1027.eqiad.wmnet',
    ]

    # set up rsync modules for copying files
    # on statistic servers in $working_path
    class { 'misc::statistics::rsyncd':
        hosts_allow => $servers,
        path        => $working_path,
    }
}

class misc::statistics::packages {
    package { [
        'mc',
        'zip',
        'p7zip',
        'p7zip-full',
        'subversion',
        'mercurial',
        'nodejs',
        'tofrodos',
        'git-review',
        'imagemagick',
        # halfak wants make to manage dependencies
        'make',
        # for checking up on eventlogging
        'zpubsub',
        # libwww-perl for wikistats stuff
        'libwww-perl',
        'libgdal1-dev', # Requested by lzia for rgdal
        'libproj-dev', # Requested by lzia for rgdal
        'php5-cli',
        'php5-mysql',
        'sqlite3', # For storing and interacting with intermediate results
        'libbz2-dev' # for compiling some python libs.  RT 8278
    ]:
        ensure => 'latest',
    }

    include misc::statistics::packages::python
    # include mysql module base class to install mysql client
    class { '::mysql': }
}


# Packages needed for various python stuffs
# on statistics servers.
class misc::statistics::packages::python {
    package { [
        'python-geoip',
        'libapache2-mod-python',
        'python-django',
        'python-mysqldb',
        'python-yaml',
        'python-dateutil',
        'python-numpy',
        'python-scipy',
        'python-boto',      # Amazon S3 access (needed to get zero sms logs)
        'python-pandas',    # Pivot tables processing
        'python-requests',  # Simple lib to make API calls
        'python-unidecode', # Unicode simplification - converts everything to latin set
        'python-pygeoip',   # For geo-encoding IP addresses
        'python-ua-parser', # For parsing User Agents
    ]:
        ensure => 'installed',
    }
}

# Installs java.
class misc::statistics::packages::java {
    if !defined(Package['openjdk-7-jdk']) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }
}

# Mounts /data from dataset1001 server.
# xmldumps and other misc files needed
# for generating statistics are here.
class misc::statistics::dataset_mount {
    # need this for NFS mounts.
    include nfs::common

    file { '/mnt/data':
        ensure => 'directory',
    }

    mount { '/mnt/data':
        ensure  => 'mounted',
        device  => '208.80.154.11:/data',
        fstype  => 'nfs',
        options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.154.11',
        atboot  => true,
        require => [File['/mnt/data'], Class['nfs::common']],
    }
}


# clones mediawiki core at $working_path/mediawiki/core
# and ensures that it is at the latest revision.
# RT 2162
class misc::statistics::mediawiki {
    include misc::statistics::base

    $statistics_mediawiki_directory = "${misc::statistics::base::working_path}/mediawiki/core"

    git::clone { 'statistics_mediawiki':
        ensure    => 'latest',
        directory => $statistics_mediawiki_directory,
        origin    => 'https://gerrit.wikimedia.org/r/p/mediawiki/core.git',
        owner     => 'mwdeploy',
        group     => 'wikidev',
    }
}

# wikistats configuration for generating
# stats.wikimedia.org data.
#
# TODO: puppetize clone of wikistats?
class misc::statistics::wikistats {
    include misc::statistics::base

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
        ensure => 'installed',
    }

    # generates the new mobile pageviews report
    # and syncs the file PageViewsPerMonthAll.csv to stat1002
    cron { 'new mobile pageviews report':
        command  => "/bin/bash ${misc::statistics::base::working_path}/wikistats_git/pageviews_reports/bin/stat1-cron-script.sh",
        user     => 'stats',
        monthday => 1,
        hour     => 7,
        minute   => 20,
    }
}

# RT-2163
class misc::statistics::plotting {

    package { [
            'ploticus',
            'libploticus0',
            'r-base',
            'r-cran-rmysql',
            'libcairo2',
            'libcairo2-dev',
            'libxt-dev'
        ]:
        ensure => installed,
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

    include ::apache::mod::rewrite
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http
}

# reportcard.wikimedia.org
class misc::statistics::sites::reportcard {
    require misc::statistics::webserver
    misc::limn::instance { 'reportcard': }
}

# rsync sanitized data that has been readied for public consumption to a
# web server.
class misc::statistics::public_datasets {
    include misc::statistics::base

    $working_path = $misc::statistics::base::working_path
    file { [
        "${working_path}/public-datasets",
        "${working_path}/aggregate-datasets"
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink /var/www/public-datasets to $working_path/public-datasets
    file { '/var/www/public-datasets':
        ensure => 'link',
        target => "${working_path}/public-datasets",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink /var/www/aggregate-datasets to $working_path/aggregate-datasets
    file { '/var/www/aggregate-datasets':
        ensure => 'link',
        target => "${working_path}/aggregate-datasets",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # rsync from stat1003:/srv/public-datasets to $working_path/public-datasets
    cron { 'rsync public datasets':
        command => "/usr/bin/rsync -rt --delete stat1003.wikimedia.org::srv/public-datasets/* ${working_path}/public-datasets/",
        require => File["${working_path}/public-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    # rsync from stat1002:/srv/aggregate-datasets to $working_path/aggregate-datasets
    cron { 'rsync aggregate datasets from stat1002':
        command => "/usr/bin/rsync -rt --delete stat1002.wikimedia.org::srv/aggregate-datasets/* ${working_path}/aggregate-datasets/",
        require => File["${working_path}/aggregate-datasets"],
        user    => 'root',
        minute  => '*/30',
    }
}

# stats.wikimedia.org
class misc::statistics::sites::stats {
    include misc::statistics::base
    require misc::statistics::geowiki::data::private

    $site_name                     = 'stats.wikimedia.org'
    $docroot                       = "/srv/${site_name}/htdocs"
    $geowiki_private_directory     = "${docroot}/geowiki-private"
    $geowiki_private_htpasswd_file = '/etc/apache2/htpasswd.stats-geowiki'

    # add htpasswd file for stats.wikimedia.org
    file { '/etc/apache2/htpasswd.stats':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        source  => 'puppet:///private/apache/htpasswd.stats',
    }

    # add htpasswd file for private geowiki data
    file { $geowiki_private_htpasswd_file:
        owner   => 'root',
        group   => 'www-data',
        mode    => '0640',
        source  => 'puppet:///private/apache/htpasswd.stats-geowiki',
    }

    # link geowiki checkout from docroot
    file { $geowiki_private_directory:
        ensure  => 'link',
        target  => "${misc::statistics::geowiki::data::private::geowiki_private_data_path}/datafiles",
        owner   => 'root',
        group   => 'www-data',
        mode    => '0750',
    }

    install_certificate{ $site_name: }

    apache::site { $site_name:
        content => template("apache/sites/${site_name}.erb"),
    }

    file { '/etc/apache2/ports.conf':
        ensure  => 'present',
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///files/apache/ports.conf.ssl',
    }
}

# community-analytics.wikimedia.org
class misc::statistics::sites::community_analytics {
    include misc::statistics::base

    $site_name = 'community-analytics.wikimedia.org'
    $docroot   = '/srv/org.wikimedia.community-analytics/community-analytics/web_interface'

    # org.wikimedia.community-analytics is kinda big,
    # it really lives on $working_path.
    # Symlink /srv/a/org.wikimedia.community-analytics to it.
    # Oof, this /srv | /a stuff is a mess... :(
    file { '/srv/org.wikimedia.community-analytics':
        ensure => "${misc::statistics::base::working_path}/srv/org.wikimedia.community-analytics",
    }

    webserver::apache::site { $site_name:
        require      => [Class['webserver::apache'], Class['misc::statistics::packages::python']],
        docroot      => $docroot,
        server_admin => 'noc@wikimedia.org',
        custom       => [
            'SetEnv MPLCONFIGDIR /srv/org.wikimedia.community-analytics/mplconfigdir',

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

# mertics.wikimedia.org and metrics-api.wikimedia.org
# They should just redirect to Wikimetrics
#
class misc::statistics::sites::metrics {
    require misc::statistics::user

    $site_name       = 'metrics.wikimedia.org'
    $redirect_target = 'https://metrics.wmflabs.org/'

    include webserver::apache
    include ::apache::mod::alias

    # Set up the VirtualHost
    apache::site { $site_name:
        content => template("apache/sites/${site_name}.erb"),
    }

    # make access and error log for metrics-api readable by wikidev group
    file { ['/var/log/apache2/access.metrics.log', '/var/log/apache2/error.metrics.log']:
        group   => 'wikidev',
    }
}

# == Class misc::statistics::sites::datasets
class misc::statistics::sites::datasets {
    apache::site { 'datasets':
        source => 'puppet:///files/apache/sites/datasets.wikimedia.org',
    }
}


# installs MonogDB
class misc::statistics::db::mongo {
    include misc::statistics::base

    class { 'mongodb':
        dbpath    => "${misc::statistics::base::working_path}/mongodb",
    }
}

# Install dev environments
class misc::statistics::dev {
    package { [
        'python-dev',  # RT 6561
        'python3-dev', # RT 6561
        'build-essential', # Requested by halfak to install SciPy
    ]:
        ensure => 'installed',
    }
}


# Sets up rsyncd and common modules
# for statistic servers.  Currently
# this is read/write between statistic
# servers in /srv or /a.
#
# Parameters:
#   hosts_allow - array.  Hosts to grant rsync access.
class misc::statistics::rsyncd(
    $hosts_allow = undef,
    $path        = '/srv'
)
{
    # this uses modules/rsync to
    # set up an rsync daemon service
    include rsync::server

    # Set up an rsync module
    # (in /etc/rsync.conf) for /srv.
    rsync::server::module { 'srv':
        path        => $path,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
    }

    # Set up an rsync module
    # (in /etc/rsync.conf) for /var/www.
    # This will allow $hosts_allow to host public data files
    # from the default Apache VirtualHost.
    rsync::server::module { 'www':
        path        => '/var/www',
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
    }

    # Allow rsyncd traffic from internal networks.
    # and stat* public IPs.
    ferm::service { 'rsync':
        proto  => 'tcp',
        port   => '873',
        srange => '($INTERNAL 208.80.154.155/32 208.80.154.82/32)',
    }
}



# Class: misc::statistics::rsync::jobs::webrequest
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class misc::statistics::rsync::jobs::webrequest {
    include misc::statistics::base
    $working_path = $misc::statistics::base::working_path

    # Make sure destination directories exist.
    # Too bad I can't do this with recurse => true.
    # See: https://projects.puppetlabs.com/issues/86
    # for a much too long discussion on why I can't.
    file { [
        "${working_path}/aft",
        "${working_path}/aft/archive",
        "${working_path}/public-datasets",
    ]:
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # Make sure destination directories exist.
    # Too bad I can't do this with recurse => true.
    # See: https://projects.puppetlabs.com/issues/86
    # for a much too long discussion on why I can't.
    file { [
        "${working_path}/squid",
        "${working_path}/squid/archive",
        # Moving away from "squid" nonmenclature for
        # webrequest logs.  Kafkatee generated log
        # files will be rsynced into /a/log.
        "${working_path}/log",
        "${working_path}/log/webrequest",
    ]:
        ensure  => directory,
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0755',
    }

    # wikipedia zero logs from oxygen
    misc::statistics::rsync_job { 'wikipedia_zero':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/zero*.gz',
        destination => "${working_path}/squid/archive/zero",
    }

    # API logs from erbium
    misc::statistics::rsync_job { 'api':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/api-usage*.gz',
        destination => "${working_path}/squid/archive/api",
    }

    # sampled-1000 logs from erbium
    misc::statistics::rsync_job { 'sampled_1000':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/sampled-1000*.gz',
        destination => "${working_path}/squid/archive/sampled",
    }

    # glam_nara logs from erbium
    misc::statistics::rsync_job { 'glam_nara':
        source      => 'erbium.eqiad.wmnet::udp2log/webrequest/archive/glam_nara*.gz',
        destination => "${working_path}/squid/archive/glam_nara",
    }

    # edit logs from oxygen
    misc::statistics::rsync_job { 'edits':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/edits*.gz',
        destination => "${working_path}/squid/archive/edits",
    }

    # mobile logs from oxygen
    misc::statistics::rsync_job { 'mobile':
        source      => 'oxygen.wikimedia.org::udp2log/webrequest/archive/mobile*.gz',
        destination => "${working_path}/squid/archive/mobile",
    }

    # rsync kafkatee generated webrequest logs
    misc::statistics::rsync_job { 'webrequest_mobile':
        source      => 'analytics1003.eqiad.wmnet::webrequest/archive/mobile*.gz',
        destination => "${working_path}/log/webrequest/mobile",
    }
    # rsync kafkatee generated webrequest logs
    misc::statistics::rsync_job { 'webrequest_zero':
        source      => 'analytics1003.eqiad.wmnet::webrequest/archive/zero*.gz',
        destination => "${working_path}/log/webrequest/zero",
    }
}

# Class: misc::statistics::rsync::jobs::eventlogging
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class misc::statistics::rsync::jobs::eventlogging {
    include misc::statistics::base
    $working_path = $misc::statistics::base::working_path

    file { "${working_path}/eventlogging":
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # eventlogging logs from vanadium
    misc::statistics::rsync_job { 'eventlogging':
        source      => 'vanadium.eqiad.wmnet::eventlogging/archive/*.gz',
        destination => "${working_path}/eventlogging/archive",
    }
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
        ensure  => 'directory',
        owner   => $misc::statistics::user::username,
        group   => 'wikidev',
        mode    => '0755',
    }

    # Create a daily cron job to rsync $source to $destination.
    # This requires that the $misc::statistics::user::username
    # user is installed on the source host.
    cron { "rsync_${name}_logs":
        command => "/usr/bin/rsync -rt --perms --chmod=g-w ${source} ${destination}/",
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
    include misc::statistics::base
    include passwords::mysql::research

    $working_path      = $misc::statistics::base::working_path

    $source_dir        = "${working_path}/limn-mobile-data"
    $command           = "${source_dir}/generate.py"
    $config            = "${source_dir}/mobile/"
    $mysql_credentials = "${working_path}/.my.cnf.research"
    $rsync_from        = "${working_path}/limn-public-data"
    $output            = "${rsync_from}/mobile/datafiles"
    $log               = '/var/log/limn-mobile-data.log'
    $gerrit_repo       = 'https://gerrit.wikimedia.org/r/p/analytics/limn-mobile-data.git'
    $user              = $misc::statistics::user::username

    $db_user           = $passwords::mysql::research::user
    $db_pass           = $passwords::mysql::research::pass

    git::clone { 'analytics/limn-mobile-data':
        ensure    => 'latest',
        directory => $source_dir,
        origin    => $gerrit_repo,
        owner     => $user,
        require   => [User[$user]],
    }

    file { $log:
        ensure  => 'present',
        owner   => $user,
        group   => $user,
        mode    => '0660',
    }

    file { $mysql_credentials:
        owner   => $user,
        group   => $user,
        mode    => '0600',
        content => template('misc/mysql-config-research.erb'),
    }

    file { [$source_dir, $rsync_from, $output]:
        ensure => 'directory',
        owner  => $user,
        group  => wikidev,
        mode   => '0775',
    }

    cron { 'rsync_mobile_apps_stats':
        command => "python ${command} ${config} >> ${log} 2>&1 && /usr/bin/rsync -rt ${rsync_from}/* stat1001.wikimedia.org::www/limn-public-data/",
        user    => $user,
        minute  => 0,
    }
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
    $geowiki_private_data_bare_host_fqdn = "${geowiki_private_data_bare_host}.wikimedia.org"

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
        include backup::host
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
        misc::statistics::geowiki::data::private,
        misc::statistics::packages::python

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

# password to access the research database
# 'researchers' group has read access
class misc::statistics::researchdb_password {

    include passwords::mysql::research

    file { '/srv/passwords':
        ensure => 'directory',
        owner  => 'root',
        group  => 'researchers',
        mode   => '0555',
    }

    file { '/srv/passwords/researchdb':
        owner   => 'root',
        group   => 'researchers',
        mode    => '0440',
        content => "user: ${::passwords::mysql::research::user}\npass: ${::passwords::mysql::research::pass}\n"
    }
}
