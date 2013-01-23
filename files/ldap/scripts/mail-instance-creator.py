#!/usr/bin/python

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/ldap/scripts/mail-instance-creator.py
#####################################################################


import urllib
import os

from xml.dom import minidom
from optparse import OptionParser
from socket import gethostname


def main():
    parser = OptionParser(conflict_handler="resolve")
    parser.set_usage("mail-instance-creator.py <from-email-address> <to-email-address> <languagecode> <wikiaddress>\n\n\texample: mail-instance-creator.py 'test@example.com' 'es' 'http://example.com/w/'")

    (options, args) = parser.parse_args()

    if len(args) != 4:
        parser.error("mail-instance-creator.py expects exactly four arguments.")

    fromaddress = args[0]
    toaddress = args[1]
    lang = args[2]
    wikiaddress = args[3]
    subjecturl = wikiaddress + 'api.php?action=expandtemplates&text={{msgnw:mediawiki:openstackmanager-email-subject/' + lang + '}}&format=xml'
    bodyurl = wikiaddress + 'api.php?action=expandtemplates&text={{msgnw:mediawiki:openstackmanager-email-body/' + lang + '}}&format=xml'
    dom = minidom.parse(urllib.urlopen(subjecturl))
    subject = dom.getElementsByTagName('expandtemplates')[0].firstChild.data
    dom = minidom.parse(urllib.urlopen(bodyurl))
    body = dom.getElementsByTagName('expandtemplates')[0].firstChild.data
    body = body + ' ' + gethostname()
    sendmail_location = "/usr/sbin/sendmail"  # sendmail location
    p = os.popen("%s -t" % sendmail_location, "w")
    p.write("From: %s\n" % fromaddress)
    p.write("To: %s\n" % toaddress)
    p.write("Subject: %s\n" % subject)
    p.write("\n")  # blank line separating headers from body
    p.write(body)
    status = p.close()
    return status

if __name__ == "__main__":
    main()
