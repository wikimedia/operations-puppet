# Given nginx will be installed on a system where apache is already
# running, the postinst script will fail to start it with the default
# configuration as port 80 is already in use. This is considered working
# as designed by Debian, see
#    https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=754407
# However, we need the installation to complete correctly for puppet to
# work as expected, hence we pre-install a configuration that will make
# that possible. Note this file will be overwritten by puppet when
# the nginx configuration gets installed properly.
class tlsproxy::nginx_bootstrap {
    exec { 'Dummy nginx.conf for installation':
        command => '/bin/mkdir -p /etc/nginx && /bin/echo -e "events { worker_connections 1; }\nhttp{ server{ listen 666; }}\n" > /etc/nginx/nginx.conf',
        creates => '/etc/nginx/nginx.conf',
        before  => Package['nginx-full'],
    }
}
