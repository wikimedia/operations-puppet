# == Class: role::zotero
#
# Zotero is a free and open-source reference management software
# for bibliographic data and related research materials.
# See <https://en.wikipedia.org/wiki/Zotero>.
#
# filtertags: labs-project-deployment-prep
class role::zotero {
    system::role { 'zotero': description => "Zotero ${::realm}" }

    include ::profile::zotero
}
