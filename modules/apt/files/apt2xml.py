#!/usr/bin/env python
# -*- coding: utf-8 -*- vim:encoding=utf-8:
# vim: tabstop=4:shiftwidth=4:softtabstop=4:expandtab

# Copyright © 2010-2012 Greek Research and Technology Network (GRNET S.A.)
# Copyright © 2012 Faidon Liambotis
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH REGARD
# TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS. IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
# OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
# USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THIS SOFTWARE.

from socket import getfqdn
import warnings
warnings.filterwarnings('ignore')
import apt
from xml.dom.minidom import Document


# shamelessly stolen from /usr/lib/update-notifier/apt_check.py ported/modified
def isSecurityUpgrade(candidate):
    "check if the given version is a security update (or masks one)"

    for origin in candidate.origins:
        if (origin.origin == "Debian" and
            (origin.label == "Debian-Security" or
             origin.site == "security.debian.org")):
            return True

        if (origin.origin == "Ubuntu" and
            origin.archive.endswith('-security')):
            return True
    return False


def getUpdates():
    cache = apt.Cache()
    cache.upgrade(dist_upgrade=True)

    updates = cache.get_changes()
    doc = Document()

    host = doc.createElement("host")
    host.setAttribute("name", getfqdn())

    doc.appendChild(host)

    for update in updates:
        u = doc.createElement("package")
        u.setAttribute("name", update.name)
        if update.installed:
            u.setAttribute("current_version", update.installed.version)
        u.setAttribute("new_version", update.candidate.version)
        u.setAttribute("source_name", update.candidate.source_name)

        try:
            origin = update.candidate.origins[0].origin
            u.setAttribute("origin", origin)
        except IndexError:
            pass

        if isSecurityUpgrade(update.candidate):
            u.setAttribute("is_security", "true")

        host.appendChild(u)

    return doc.toxml().replace('\n', '')

if __name__ == '__main__':
    print getUpdates()
