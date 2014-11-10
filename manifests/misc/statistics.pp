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
        'stat1001.eqiad.wmnet',
        'stat1002.eqiad.wmnet',
        'stat1003.eqiad.wmnet',
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
    require_package('nodejs')

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
        # halfak wants make to manage dependencies
        'make',
        # for checking up on eventlogging
        'zpubsub',
        # libwww-perl for wikistats stuff
        'libwww-perl',
        'php5-cli',
        'php5-mysql',
        'sqlite3', # For storing and interacting with intermediate results
    ]:
        ensure => 'latest',
    }

    include misc::statistics::packages::python
    # include mysql module base class to install mysql client
    class { '::mysql': }
}

# packages used on stat1002 and stat1003 for analytics
# user utilities.
class misc::statistics::packages::utilities {
    package { [
        'libgdal1-dev', # Requested by lzia for rgdal
        'libproj-dev', # Requested by lzia for rgdal
        'libbz2-dev', # for compiling some python libs.  RT 8278
        'libboost-regex-dev',  # Ironholds wants these
        'libboost-system-dev',
        'libyaml-cpp0.3',
        'libyaml-cpp0.3-dev',
        'libgoogle-glog-dev',
        'libboost-iostreams-dev',
        'libmaxminddb-dev',
    ]:
        ensure => 'latest',
    }
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
        'python-matplotlib',  # For generating plots of data
        'python-netaddr',
        'python-virtualenv', # T84378
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
    include ::apache::mod::headers

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
        command => "/usr/bin/rsync -rt --delete stat1003.eqiad.wmnet::srv/public-datasets/* ${working_path}/public-datasets/",
        require => File["${working_path}/public-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    # rsync from stat1002:/srv/aggregate-datasets to $working_path/aggregate-datasets
    cron { 'rsync aggregate datasets from stat1002':
        command => "/usr/bin/rsync -rt --delete stat1002.eqiad.wmnet::srv/aggregate-datasets/* ${working_path}/aggregate-datasets/",
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
    # (in /etc/rsyncd.conf) for /srv.
    rsync::server::module { 'srv':
        path        => $path,
        read_only   => 'no',
        list        => 'yes',
        hosts_allow => $hosts_allow,
    }

    # Set up an rsync module for /a if
    # we are using /srv a working path on this node.
    # This if for backwards compatibility.
    if ($path == '/srv') {
        rsync::server::module { 'a':
            path        => $path,
            read_only   => 'no',
            list        => 'yes',
            hosts_allow => $hosts_allow,
        }
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
        srange => '($INTERNAL)',
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
}

# Class: misc::statistics::rsync::jobs::eventlogging
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class misc::statistics::rsync::jobs::eventlogging {
    include misc::statistics::base
    $working_path = $misc::statistics::base::working_path
    # Any logs older than this will be pruned by
    # the rsync_job define.
    $retention_days = 90

    file { "${working_path}/eventlogging":
        ensure  => 'directory',
        owner   => 'stats',
        group   => 'wikidev',
        mode    => '0775',
    }

    # eventlogging logs from vanadium
    misc::statistics::rsync_job { 'eventlogging':
        source         => 'vanadium.eqiad.wmnet::eventlogging/archive/*.gz',
        destination    => "${working_path}/eventlogging/archive",
        retention_days => $retention_days,

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
#    source         - rsync source argument (including hostname)
#    destination    - rsync destination argument
#    retention_days - If set, a cron will be installed to remove files older than this many days from $destination.
#
define misc::statistics::rsync_job($source, $destination, $retention_days = undef) {
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

    $prune_old_logs_ensure = $retention_days ? {
        undef   => 'absent',
        default => 'present',
    }

    cron { "prune_old_${name}_logs":
        ensure  => $prune_old_logs_ensure,
        command => "/usr/bin/find ${destination} -ctime +${retention_days} -exec rm {} \\;",
        user    => $misc::statistics::user::username,
        minute  => 0,
        hour    => 9,
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

# == Class misc::statistics::limn::data
# Sets up base directories and repositories
# for using the misc::statistics::limn::data::generate() define.
#
class misc::statistics::limn::data {
    include misc::statistics::base
    include misc::statistics::stats_researchdb_password

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

    # This file will render at
    # /etc/mysql/conf.d/research-client.cnf.
    mysql::config::client { 'research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => 'researchers',
        mode  => '0440',
    }
}

# Same as above, but renders a file readable by the stats user.
class misc::statistics::stats_researchdb_password {
    include misc::statistics::user

    # This file will render at
    # /etc/mysql/conf.d/stats-research-client.cnf.
    mysql::config::client { 'stats-research':
        user  => $::passwords::mysql::research::user,
        pass  => $::passwords::mysql::research::pass,
        group => $misc::statistics::user::username,
        mode  => '0440',
    }
}

# == Class misc::statistics::aggregator
# Handles aggregation of pagecounts-all-sites projectcounts files
class misc::statistics::aggregator {
    include misc::statistics::base
    include misc::statistics::user

    Class['cdh::hadoop::mount'] -> Class['misc::statistics::aggregator']

    $working_path     = "${misc::statistics::base::working_path}/aggregator"

    $script_path      = "${working_path}/scripts"
    $data_repo_path   = "${working_path}/data"
    $data_path        = "${data_repo_path}/projectcounts"
    $log_path         = "${working_path}/log"
    $hdfs_source_path = "${cdh::hadoop::mount::mount_point}/wmf/data/archive/pagecounts-all-sites"
    $user             = $misc::statistics::user::username
    $group            = $misc::statistics::user::username

    git::clone { 'aggregator_code':
        ensure    => 'latest',
        directory => $script_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator.git',
        owner     => $user,
        group     => $group,
        mode      => '0750',
    }

    git::clone { 'aggregator_data':
        ensure    => 'latest',
        directory => $data_repo_path,
        origin    => 'https://gerrit.wikimedia.org/r/p/analytics/aggregator/data.git',
        owner     => $user,
        group     => $group,
        mode      => '0750',
    }

    file { $log_path:
        ensure => directory,
        owner  => $user,
        group  => $group,
        mode   => '0750',
    }

    # Cron for doing the basic aggregation step itself
    cron { 'aggregator projectcounts aggregate':
        command => "${script_path}/bin/aggregate_projectcounts --source ${hdfs_source_path} --target ${data_path} --first-date=`date --date='-8 day' +\\%Y-\\%m-\\%d` --last-date=`date --date='-1 day' +\\%Y-\\%m-\\%d` --push-target --log ${log_path}/`date +\\%Y-\\%m-\\%d--\\%H-\\%M-\\%S`.log",
        require => File[$log_path],
        user    => $user,
        hour    => '13',
        minute  => '0',
    }

    # Cron for basing monitoring of the aggregated data
    cron { 'aggregator projectcounts monitor':
        monitor => "${script_path}/bin/check_validity_aggregated_projectcounts --data ${data_path}",
        user    => $user,
        hour    => '13',
        minute  => '45',
    }
}
