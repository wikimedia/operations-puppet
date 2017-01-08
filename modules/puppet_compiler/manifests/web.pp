# === Class puppet_compiler::web
#
class puppet_compiler::web($ensure='present') {
    nginx::site {'puppet-compiler':
        ensure  => $ensure,
        content => template('puppet_compiler/nginx_site.erb'),
    }

    file_line { 'modify_nginx_magic_types':
        path    => '/etc/nginx/mime.types',
        line    => "    text/plain                            txt pson err diff;",
        match   => '\s+text/plain\s+txt',
        require => Nginx::Site['puppet-compiler'],
        notify  => Service['nginx'],
    }
}
