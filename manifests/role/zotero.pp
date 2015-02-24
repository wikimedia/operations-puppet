# == Class: role::zotero
#
# Zotero /zoʊˈtɛroʊ/ is free and open-source reference management
# software to manage bibliographic data and related research materials.
# https://en.wikipedia.org/wiki/Zotero
#

@monitoring::group { 'zotero_eqiad': description => 'Zotero eqiad' }
@monitoring::group { 'zotero_codfw': description => 'Zotero codfw' }

class role::zotero {
    system::role { 'zotero': description => "Zotero ${::realm}" }

    # to be activated once we have the module ready
    # include ::zotero
    # include lvs::realserver

}

