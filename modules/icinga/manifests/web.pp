# = Class: icinga::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga::web (
    String $icinga_user,
    String $icinga_group,
    String $apache2_htpasswd_salt,
    Hash[String, String] $apache2_auth_users,
) {

    # Apparently required for the web interface
    package { 'icinga-doc':
        ensure => present,
    }

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => $icinga_user,
        group  => $icinga_group,
        mode   => '0644',
    }

    # The first url is a note_url:
    file { '/usr/share/icinga/htdocs/images/1-notes.gif':
        ensure => link,
        target => 'notes.gif',
    }

    # Allow up to 4 dashboard_url URLs
    ['2', '3', '4', '5'].each |$note_id| {
        file { "/usr/share/icinga/htdocs/images/${note_id}-notes.gif":
            ensure => link,
            target => 'stats.gif',
        }
    }

    # Shared with icinga::external_monitoring
    $auth_user_file = '/etc/icinga/apache2_auth_user_file'
    file { $auth_user_file:
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        content => template('icinga/apache2_auth_user_file.erb'),
    }

    $alias_config = @(ALIAS)
        LoadModule alias_module modules/mod_alias.so
        ScriptAlias /icinga/cgi-bin /usr/lib/cgi-bin/icinga
        ScriptAlias /cgi-bin/icinga /usr/lib/cgi-bin/icinga
        Alias /icinga/stylesheets /etc/icinga/stylesheets
        Alias /icinga /usr/share/icinga/htdocs
    | ALIAS
    httpd::conf{'icinga_alias':
        content => $alias_config,
    }
    httpd::conf{'icinga_handler':
        content => "AddHandler cgi-script .cgi\n",
    }

    # remove icinga default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga.conf':
        ensure => absent,
    }
}
