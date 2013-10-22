# Class: puppetmaster::scripts
#
# This class installs some puppetmaster server side scripts required for the manifests
class puppetmaster::scripts {
    File { mode => 0555 }
    file {
        "/usr/local/bin/uuid-generator":
            source => "puppet:///modules/puppetmaster/uuid-generator";
        "/usr/local/bin/naggen":
            source => "puppet:///modules/puppetmaster/naggen";
        "/usr/local/sbin/puppetstoredconfigclean.rb":
            source => "puppet:///modules/puppetmaster/puppetstoredconfigclean.rb";
        "/usr/local/bin/decom_servers.sh":
            content => template("puppetmaster/decom_servers.sh.erb");
        "/usr/local/bin/puppet-merge":
            source => "puppet:///modules/puppetmaster/puppet-merge";
    }

    # Clear out reports older than 36 hours.
    cron {
        removeoldreports:
            command => "find /var/lib/puppet/reports -type f -mmin +2160 -delete",
            user => puppet,
            hour => [4,16],
            minute => 27,
            ensure => present;
    }

    # Disable the decomserver cron if not running in production
    # or if running on the production puppetmaster.
    if (($::realm != 'production') or ($puppetmaster::config['thin_storeconfigs'] != true)) {
      $decomservercron = absent
    }
    else {
      $decomservercron = present
    }

    cron {
        decomservers:
            command => "/usr/local/bin/decom_servers.sh",
            user => root,
            minute => 17,
            ensure => $decomservercron;
    }
}
