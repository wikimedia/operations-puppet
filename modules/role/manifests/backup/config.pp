class role::backup::config {
    # if you change the director host name
    # you (likely) also need to change the IP,
    # we don't want to rely on DNS in firewall rules
    $director    = 'helium.eqiad.wmnet'
    $director_ip = '10.64.0.179'
    $director_ip6 = '2620:0:861:101:10:64:0:179'
    $database = 'm1-master.eqiad.wmnet'
    $days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri']
    $pool = 'production'
    $offsite_pool = 'offsite'
    $onsite_sd = 'helium'
    $offsite_sd = 'heze'
}

