# realm.pp
# Collection of global definitions used across sites, within one realm.
#

# monkey patch early
wmflib::monkey_patch()

# Determine the site the server is in
# NOTE: Adding a new site or updating private ranges?
# Please update the ranges in mediawiki-config/wmf-config/reverse-proxy.php.
# See I385fe5bef47dc04 for a sample commit.

$site = $facts['ipaddress'] ? {
    /^208\.80\.15[45]\./                                      => 'eqiad',
    /^10\.6[48]\./                                            => 'eqiad',
    /^172\.16\.([0-9]|[1-9][0-9]|1([0-1][0-9]|2[0-7]))\./     => 'eqiad',
    /^208\.80\.15[23]\./                                      => 'codfw',
    /^10\.19[26]\./                                           => 'codfw',
    /^172\.16\.(1(2[8-9]|[3-9][0-9])|2([0-4][0-9]|5[0-5]))\./ => 'codfw',
    /^185\.15\.59\./                                          => 'esams',
    /^10\.80\./                                               => 'esams',
    /^198\.35\.26\./                                          => 'ulsfo',
    /^10\.128\./                                              => 'ulsfo',
    /^103\.102\.166\./                                        => 'eqsin',
    /^10\.132\./                                              => 'eqsin',
    /^185\.15\.58\./                                          => 'drmrs',
    /^10\.136\./                                              => 'drmrs',
    /^195\.200\.68\./                                         => 'magru',
    /^10\.140\./                                              => 'magru',
    default                                                   => '(undefined)'
}
# trusted facts are not always available with puppet master --compile (used by pcc)
# or puppet lookup --compile.  As such we use the fqdn when the trusted facts are
# not available T248169
$_trusted_certname = $trusted['certname'].lest || { $facts['fqdn'] }
unless($_trusted_certname) {
    fail("unable to determine \$_trusted_certname: from trusted (${trusted['certname']} or facts (${facts['fqdn']})")
}
if $_trusted_certname =~ '\.wmflabs$' or $_trusted_certname =~ '\.wikimedia.cloud$' {
    $realm = 'labs'
    # Pull the project name from the certname. CloudVPS VM certs can be:
    #  * <hostname>.<projname>.<site>.wmflabs
    #  * <hostname>.<projname>.<deployment>.wikimedia.cloud
    #
    # See following page for additional context:
    # https://wikitech.wikimedia.org/wiki/Wikimedia_Cloud_Services_team/EnhancementProposals/DNS_domain_usage#Resolution
    $pieces = $_trusted_certname.split('[.]')

    # current / legacy FQDN.
    # This whole branch will go away eventually
    if $pieces[-1] == 'wmflabs' {
        if $pieces[2] != $site {
            fail("Incorrect site in certname. Should be ${site} but is ${pieces[2]}")
        }
        $labsproject = $pieces[1]
        $wmcs_project = $pieces[1]
        $wmcs_deployment = $pieces[2] ? {
            'eqiad' => 'eqiad1',
            'codfw' => 'codfw1dev',
            default => fail("site (${pieces[2]}) is not supported")
        }
    } else {
        # new FQDN wikimedia.cloud
        $labsproject = $pieces[1] # $wmcs_project may make more sense
        $wmcs_project = $pieces[1]
        $wmcs_deployment = $pieces[2]
    }

    # some final checks before we move on
    if $pieces[0] != $::hostname {
        fail("Cert hostname ${pieces[0]} does not match reported hostname ${::hostname}")
    }
    if $::labsproject == undef {
        fail('Failed to determine $::labsproject')
    }
    if $::wmcs_project == undef {
        fail('Failed to determine $::wmcs_project')
    }
    if $::wmcs_deployment == undef {
        fail('Failed to determine $::wmcs_deployment')
    }
    $projectgroup = "project-${labsproject}"

    $_nameservers = lookup('profile::resolving::nameservers')
    $nameservers = $_nameservers.map |$ns| {
        if $ns =~ Stdlib::IP::Address {
            $ns
        } else {
            dnsquery::a($ns)[0]
        }
    }
} else {
    $realm = 'production'
    $nameservers = [ '10.3.0.1' ] # anycast
}

# This is used to define the fallback site and is to be used by applications that
# are capable of automatically detecting a failed service and falling back to
# another one. Only the 2 sites that make sense to really be here are added for
# now
$other_site = $site ? {
    'codfw' => 'eqiad',
    'eqiad' => 'codfw',
    default => '(undefined)'
}

$network_zone = $facts['ipaddress'] ? {
    /^10./  => 'internal',
    default => 'public'
}

# Resource defaults
File {
    owner => 'root',
    group => 'root',
}

# Ensure apt is setup how we want it, before we try to
# install any apt packages.
Package {
    # We set our package provider default to apt explicitly, so we can
    # collect it below and work around a collector limitation,
    # https://www.puppet.com/docs/puppet/7/lang_collectors.html
    provider => 'apt'
}
Class['profile::apt'] -> Package <| provider == 'apt' |>
