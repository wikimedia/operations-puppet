# == Class: role::zotero
#
# Zotero is free and open-source reference management software
# bibliographic data and related research materials.
# See <https://en.wikipedia.org/wiki/Zotero>.
#
@monitoring::group { 'zotero_eqiad': description => 'Zotero eqiad' }
@monitoring::group { 'zotero_codfw': description => 'Zotero codfw' }

class role::zotero {
    system::role { 'zotero': description => "Zotero ${::realm}" }

    ferm::service { 'zotero_http_1969':
        proto => 'tcp',
        port  => '1969',
    }

    monitoring::service { 'zotero':
        description   => 'zotero',
        check_command => 'check_http_on_port!1969',
    }

    include ::zotero
    # include lvs::realserver
}
