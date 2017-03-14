# server running "Request Tracker"
# https://bestpractical.com/request-tracker
class profile::requesttracker::server {
    system::role { 'role::requesttracker::server': description => 'RT server' }

    include passwords::misc::rt
    include ::standard
    include ::base::firewall

    class { '::requesttracker':
        apache_site => 'rt.wikimedia.org',
        dbhost      => 'm1-master.eqiad.wmnet',
        dbport      => '',
        dbuser      => $passwords::misc::rt::rt_mysql_user,
        dbpass      => $passwords::misc::rt::rt_mysql_pass,
    }

    class { 'exim4':
        variant => 'heavy',
        config  => template('role/exim/exim4.conf.rt.erb'),
        filter  => template('role/exim/system_filter.conf.erb'),
    }
    include exim4::ganglia

    # allow RT to receive mail from mail smarthosts
    ferm::service { 'rt-smtp':
        port   => '25',
        proto  => 'tcp',
        srange => inline_template('(<%= @mail_smarthost.map{|x| "@resolve(#{x})" }.join(" ") %>)'),

    }

    ferm::service { 'rt-http':
        proto => 'tcp',
        port  => '80',
    }

}
