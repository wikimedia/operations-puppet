#!/usr/bin/python

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/cgi-bin/noc/report.py
#####################################################################

# Configuration and defaults

profilehost = "professor.pmtpa.wmnet"
profileport = 3811

db="all"
sort="real"
limit=50
prefix=""


from extractprofile import ExtractProfile

import cgi
import cgitb; cgitb.enable()

import socket
import codecs
import sys


print "Content-type: text/html; charset=utf-8";
print "\n"

utf8 = codecs.getencoder("UTF-8")
form = cgi.SvFormContentDict()

if "db" in form:
    db = form["db"]

if "sort" in form:
    sort = form["sort"]

if "prefix" in form:
    prefix = form["prefix"]

if "limit" in form:
    limit=int(form["limit"])

compare="none"
if "compare" in form:
    compare = form["compare"]

class SocketSource (socket.socket):
    def read(self, what):
        enc = self.recv(what, 0)
        return enc.decode('latin-1').encode('utf-8')

sock=SocketSource()
sock.connect((profilehost, profileport))

cache={}
fullprofile=ExtractProfile().extract(sock)
try:
    events=fullprofile[db]["-"].items()
except KeyError:
    for dbname in fullprofile.keys():
        print " [<a href='report.py?db=%s'>%s</a>] " % (dbname, dbname)
        sys.exit(0)
    

cache[db]=events
cache["_dbs"]=fullprofile.keys()
dbs=cache["_dbs"]

total=fullprofile[db]["-"]["-total"]

#cache.close()
if sort=="name":
    events.sort(lambda x,y: cmp(x[0], y[0]))
else:
    events.sort(lambda y,x: cmp(x[1][sort], y[1][sort]))

def surl(stype, stext=None, limit=50):
    if (stext == None):
        stext = stype

    if stype == sort:
        return """<td>%s</td>"""%stext
    return """<td><a href='report.py?db=%s&sort=%s&limit=%d'>%s</a></td>""" % (db, stype, limit, stext)

print """
<style>
table { width: 100%; }
td { cell-padding: 1px;
    text-align: right;
    vertical-align: top;
    argin: 2px;
    border: 1px silver dotted;
    background-color: #eeeeee;
}
td.name { text-align: left; width: 100%;}
tr.head td { text-align: center; }
</style>"""

for dbname in dbs:
    if db == dbname:
        print " [%s] "% dbname
    else:
        print " [<a href='report.py?db=%s'>%s</a>] " % (dbname, dbname)

if limit==50:
    print " [ showing %d events, <a href='report.py?db=%s&sort=%s&limit=5000'>show more</a> ] " % (limit, db, sort)
else:
    print " [ showing %d events, <a href='report.py?db=%s&sort=%s&limit=50'>show less</a> ] " % (limit, db, sort)


print """
<table>
<tr class="head">"""
print surl("name")
print surl("count")
print surl("cpu","cpu%")
print surl("onecpu","cpu/c")
print surl("real","real%")
print surl("onereal","real/c")
print "</tr>"

rowformat = u"""<tr class="data"><td class="name">%s</td><td>%d</td>
    <td>%.3g</td><td>%.3g</td><td>%.3g</td><td>%.3g</td></tr>"""

for event in events:
    if event[0] == "close":
        continue
    if not event[0].startswith(prefix):
        continue
        
    limit -= 1
    if limit < 0:
        break
    row = rowformat % \
        (event[0].replace(",",", "), event[1]["count"], event[1]["cpu"] / total["cpu"] * 100, event[1]["onecpu"]  *1000,
            event[1]["real"] / total["real"] * 100, event[1]["onereal"] * 1000)
    print utf8(row)[0]

print "</table>"
