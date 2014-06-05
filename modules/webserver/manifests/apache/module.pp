define webserver::apache::module {
    Class['webserver::apache::packages'] -> Webserver::Apache::Module[$title] -> Class['webserver::apache::config']

    $packagename = $::operatingsystem ? {
        Ubuntu => $title ? {
            perl => 'libapache2-mod-perl2',

            actions         => undef,
            alias           => undef,
            apreq           => undef,
            asis            => undef,
            auth_basic      => undef,
            auth_digest     => undef,
            authn_alias     => undef,
            authn_anon      => undef,
            authn_dbd       => undef,
            authn_dbm       => undef,
            authn_default   => undef,
            authn_file      => undef,
            authnz_ldap     => undef,
            authz_dbm       => undef,
            authz_default   => undef,
            authz_groupfile => undef,
            authz_host      => undef,
            authz_owner     => undef,
            authz_user      => undef,
            autoindex       => undef,
            cache           => undef,
            cern_meta       => undef,
            cgi             => undef,
            cgid            => undef,
            charset_lite    => undef,
            dav             => undef,
            dav_fs          => undef,
            dav_lock        => undef,
            dbd             => undef,
            deflate         => undef,
            dir             => undef,
            disk_cache      => undef,
            dump_io         => undef,
            env             => undef,
            expires         => undef,
            ext_filter      => undef,
            file_cache      => undef,
            filter          => undef,
            headers         => undef,
            ident           => undef,
            imagemap        => undef,
            include         => undef,
            info            => undef,
            ldap            => undef,
            log_forensic    => undef,
            mem_cache       => undef,
            mime            => undef,
            mime_magic      => undef,
            negotiation     => undef,
            perl            => undef,
            perl2           => undef,
            proxy           => undef,
            proxy_ajp       => undef,
            proxy_balancer  => undef,
            proxy_connect   => undef,
            proxy_ftp       => undef,
            proxy_http      => undef,
            proxy_scgi      => undef,
            reqtimeout      => undef,
            rewrite         => undef,
            setenvif        => undef,
            speling         => undef,
            ssl             => undef,
            status          => undef,
            substitute      => undef,
            suexec          => undef,
            unique_id       => undef,
            userdir         => undef,
            usertrack       => undef,
            version         => undef,
            vhost_alias     => undef,

            default => "libapache2-mod-${title}"
        },
        default => "libapache2-mod-${title}"
    }

    if $packagename {
        package { $packagename:
            ensure => present;
        }
    }
    File {
        require   => $packagename ? {
            undef   => undef,
            default => Package[$packagename]
        },
        notify => Class['webserver::apache::service'],
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    file { "/etc/apache2/mods-available/${title}.conf":
        ensure => 'present',
    }

    file { "/etc/apache2/mods-available/${title}.load":
        ensure => 'present',
    }

    file { "/etc/apache2/mods-enabled/${title}.conf":
        ensure => 'link',
        target => "../mods-available/${title}.conf",
    }

    file { "/etc/apache2/mods-enabled/${title}.load":
        ensure => 'link',
        target => "../mods-available/${title}.load",
    }
}

