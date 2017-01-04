class cumin::target {
    $cumin_masters = hiera('cumin::masters')
    # FIXME: require new Puppet parser
    $ssh_authorized_sources = inline_template(
        "<%= @cumin_masters.map{|m| scope.function_ipresolve([m])}.join(',') %>")
    $cumin_master_pub_key = secret('keyholder/cumin_master.pub')

    ssh::userkey { 'root-cumin':
        ensure  => present,
        user    => 'root',
        skey    => 'cumin',
        content => template('cumin/userkey.erb'),
    }
}
