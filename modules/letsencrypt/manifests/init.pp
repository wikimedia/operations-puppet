# setup a TLS cert from letsencrypt.org
#
# General notes on ratelimits from:
# https://community.letsencrypt.org/t/rate-limits-for-lets-encrypt/6769
# (last update to that data: 2016-03-26)
#
# FQDNs/cert: 100
#   This is the SAN list of the cert.  We'll probably want to stick to a lower
#   limit than this for other reasons anyways (basic performance issues with
#   tcp congestion control and/or client interop issues).
#
# Same FQDN set: 5/week
#   (same SAN list, regardless of ordering)
#   This is most likely to bite us in the case of rapid failed
#   re-install/puppetization of a given machine or some other kind of
#   broken-ness.  All count as a one for the next limit below.
#
# Same 2LD: 20/week
#   (e.g. all new certs with any wikimedia.org hostname anywhere in SAN list):
#   We need to keep an eye on this as we roll out new LE certs for one-off
#   hosts.  This doesn't apply to "renewal" (same FQDN set as a previous valid
#   cert), but we could easily hit it if we applied this puppetization to too
#   many new (to LE) services in a big batch in a single week.
#
# Requests/IP: 500/3h
#   We're unlikely to ever hit this, except perhaps if we setup a redirector
#   service for our hundreds of junk domains, in which case we perhaps need to
#   puppet that out in blocks of names spaced out a bit.  We'd probably want to
#   space them out significantly anyways, to help spread the delays/load
#   involved in initially configuring them and then routinely renewing them.
#

class letsencrypt {
    include ::sslcert
    require sslcert::dhparam

    group { 'acme':
        ensure => present,
    }

    user { 'acme':
        ensure     => present,
        gid        => 'acme',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    # https://github.com/diafygi/acme-tiny
    file { '/usr/local/sbin/acme_tiny.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/letsencrypt/acme_tiny.py'
    }

    file { '/usr/local/sbin/acme-setup':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/letsencrypt/acme-setup',
    }

    file { '/etc/acme':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/acme/challenge-nginx.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/letsencrypt/challenge-nginx.conf',
    }

    file { '/etc/acme/challenge-apache.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/letsencrypt/challenge-apache.conf',
    }

    # LE Intermediate: current since ~2016-03-26
    if !defined(Sslcert::Ca['Lets_Encrypt_Authority_X3']) {
        sslcert::ca { 'Lets_Encrypt_Authority_X3':
            source  => 'puppet:///modules/letsencrypt/lets-encrypt-x3-cross-signed.pem'
        }
    }

    # LE Intermediate: disaster recovery fallback since ~2016-03-26
    if !defined (Sslcert::Ca['Lets_Encrypt_Authority_X4']) {
        sslcert::ca { 'Lets_Encrypt_Authority_X4':
            source  => 'puppet:///modules/letsencrypt/lets-encrypt-x4-cross-signed.pem'
        }
    }
}
