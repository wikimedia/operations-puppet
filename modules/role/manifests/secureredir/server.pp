class role::secureredir::server {
    include ::letsencrypt
    $nginx_cfg = hiera_hash('secureredirconfig', {})

    $letsencrypt_cfg = secureredir_letsencrypt(keys($nginx_cfg))
    create_resources(letsencrypt::cert::integrated, $letsencrypt_cfg)

    $fastopen_pending_max = 150 # TODO
    nginx::site { 'ncredir.wikimedia.org':
        content => template('role/secureredir/nginx.conf.erb')
    }
}
