# == Class profile::scap::dsh
#
# Installs the dsh files used by scap on a host
class profile::scap::dsh(
    Hash $groups = lookup('scap::dsh::groups'),
    Array[Stdlib::Host] $proxies = lookup('scap::dsh::scap_proxies', {'default_value' => []}),
    Array[Stdlib::Host] $masters = lookup('scap::dsh::scap_masters', {'default_value' => []}),
    String $conftool_prefix = lookup('conftool_prefix'),
){

    class { 'confd':
        interval => 300,
        prefix   => $conftool_prefix,
        srv_dns  => "${::site}.wmnet",
    }

    $scap_targets = {
        'scap_targets' => {
            'hosts' => (wmflib::class::hosts('mediawiki::scap') + wmflib::resource::hosts('scap::target')).sort.unique,
        },
    }
    class { '::scap::dsh':
        groups       => $groups + $scap_targets,
        scap_proxies => $proxies,
        scap_masters => $masters,
    }

    # Special-case file for the MediaWiki canaries
    # These need to change according to the MediaWiki active datacenter.
    # We also want the servers from each cluster in their own canary list.
    $canary_dcs = ['eqiad', 'codfw']
    $canary_clusters = ['appserver', 'api_appserver', 'jobrunner', 'parsoid']

    $canary_clusters.each |$cl| {
        # Cosmetic fix to get the same filenames as before
        $dsh_name = $cl ? {
            'api_appserver' => 'api',
            default => $cl
        }
        # We also need mediawiki-config to get the active DC.
        $keys = $canary_dcs.map |$dc| { "/pools/${dc}/${cl}/canary" } + '/mediawiki-config'
        confd::file { "/etc/dsh/group/mediawiki-${dsh_name}-canaries":
            ensure     => present,
            content    => template('profile/scap/dsh-mediawiki-canaries.tpl.erb'),
            watch_keys => $keys,
        }
    }
}
