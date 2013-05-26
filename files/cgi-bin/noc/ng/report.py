#!/usr/bin/python

#####################################################################
### THIS FILE IS MANAGED BY PUPPET
### puppet:///files/cgi-bin/noc/ng/report.py
#####################################################################

# Configuration and defaults

import config

db = config.db

sort = "real"
limit = 50

prefix = ""


from extractprofile import SocketProfile

import cgi
import sys
import cgitb
cgitb.enable()

import shelve

print "Content-type: text/html"
print "\n"

form = cgi.SvFormContentDict()
store = shelve.open('/var/run/profile-baselines')

if "db" in form:
    db = form["db"]

if "sort" in form:
    sort = form["sort"]

if "limit" in form:
    limit = int(form["limit"])

if "prefix" in form:
    prefix = form["prefix"]

if "compare" in form:
    compare = form["compare"]
    compared = store[compare]
else:
    compare = ""
    compared = None

if 'sample' not in form:
    fullprofile = SocketProfile(config.host, config.port).extract()
    sample = ""
else:
    fullprofile = store[form['sample']]
    sample = form['sample']

dbs = fullprofile.keys()
try:
    events = fullprofile[db]["-"].items()
except KeyError:
    print "<div>OMG YOU DIDNT SELECT DB OR IT DOESNT EXIST</div>"
    for dbname in dbs:
            print " [<a href='report.py?db=%s'>%s</a>] " % (dbname, dbname)
    sys.exit()
total = fullprofile[db]["-"]["-total"]

# Limit the scope
if compare:
    compared = compared[db]["-"]
    oldtotal = compared["-total"]

#cache.close()
if sort == "name":
    events.sort(lambda x, y: cmp(x[0], y[0]))
else:
    events.sort(lambda y, x: cmp(x[1][sort], y[1][sort]))


def surl(stype, stext=None, limit=50):
    """ Simple URL formatter for headers """
    if stext is None:
        stext = stype
    if stype == sort:
        return """<td><b>%s</b></td>""" % stext
    return """<td><a href='report.py?db=%s&sort=%s&limit=%d&sample=%s&compare=%s&prefix=%s'>%s</a></td>""" % (db, stype, limit, sample, compare, prefix, stext)

print """
<style>
table { width: 100%; font-size: 9pt; }
td { cell-padding: 1px;
    text-align: right;
    vertical-align: top;
    argin: 2px;
    border: 1px silver dotted;
    white-space: nowrap;
    background-color: #eeeeee;
}
td.name { text-align: left; width: 100%; white-space: normal;}
tr.head td { text-align: center; }
</style>"""

if sample:
    print "<div>Using old sample: %s, <a href='report.py?db=%s'>reset to current</a></div>" % (sample, db)

# Top list of databases
for dbname in dbs:
    if db == dbname:
        print " [%s] " % dbname
    else:
        print " [<a href='report.py?db=%s'>%s</a>] " % (dbname, dbname)

if limit == 50:
    print " [ showing %d events, <a href='report.py?db=%s&sort=%s&sample=%s&compare=%s&limit=5000'>show more</a> ] " % (limit, db, sort, sample, compare)
else:
    print " [ showing %d events, <a href='report.py?db=%s&sort=%s&sample=%s&compare=%s&limit=50'>show less</a> ] " % (limit, db, sort, sample, compare)

print " [ <a href='admin.py'>admin</a> ]</div>"

print """<form>
<input type='hidden' name='db' value='%s'>
<input type='hidden' name='sort' value='%s'>
<input type='hidden' name='limit' value='%d'>
<input type='hidden' name='sample' value='%s'>
<select name='compare'><option></option>""" % (db, sort, limit, sample)

samples = store.keys()
samples.sort()
for baseline in samples:
    print "<option%s>%s</option>" % ((compare == baseline and " SELECTED" or ""), baseline)
print "</select><input type='submit' value='compare'></form>"


# This is header!
print """
<table>
<tr class="head">"""
print surl("name")
print surl("count")
print "<td>count%</td>"
print "<td>change</td>"
#print surl("cpu","cpu%")
#print "<td>change</td>"
#print surl("onecpu","cpu/c")
#print "<td>change</td>"
print surl("real", "real%")
print "<td>change</td>"
print surl("onereal", "real/c")
print "<td>change</td>"
print "</tr>"

rowformat = """
<tr class="data"><td class="name">%s</td><td>%d</td>
<td>%.2f</td><td>%.1f</td><td>%.2f</td><td>%.1f</td></tr>"""


# name
# counts: total relative compared
# cputime: total compared percall compared
# realtime: total compared percall compared

comparedformat = """
<tr class="data"><td class="name">%s</td>
<td>%d</td><td>%.2f</td><td>%.1f</td>
<td>%.2f</td><td>%.1f</td><td>%.1f</td><td>%.1f</td>
</tr>
"""

# This is really really hacky way of reporting percentages

# And this is output of results.
for event in events:
    (name, event) = event
    if name == "close":
        continue
    if not name.startswith(prefix):
        continue
    if compared and name in compared:
        old = compared[name]
    else:
        old = None

    limit -= 1
    if limit < 0:
        break

    callcount = float(event["count"]) / total["count"]
    try:
        cpupct = event["cpu"] / total["cpu"]
    except ZeroDivisionError:
        cpupct = 0
    onecpu = event["onecpu"]
    realpct = event["real"] / total["real"]
    onereal = event["onereal"]

    if old:
        try:
            oldcount = float(old["count"]) / oldtotal["count"]
            countdiff = (callcount - oldcount) / oldcount

            oldcpupct = old["cpu"] / oldtotal["cpu"]
            cpupctdiff = (cpupct - oldcpupct) / oldcpupct

            onecpudiff = (onecpu - old["onecpu"]) / old["onecpu"]

            oldrealpct = old["real"] / oldtotal["real"]
            realpctdiff = (realpct - oldrealpct) / oldrealpct

            onerealdiff = (onereal - old["onereal"]) / old["onereal"]
        except ZeroDivisionError:
            countdiff = 0
            cpupctdiff = 0
            onecpudiff = 0
            realpctdiff = 0
            onerealdiff = 0
    else:
        countdiff = 0
        cpupctdiff = 0
        onecpudiff = 0
        realpctdiff = 0
        onerealdiff = 0

    dbg = 0

    if dbg and name == "wfMsgReal":
        print old
        print oldtotal
        print event
        print total
    if not dbg:
        print comparedformat % (name.replace(",", ", "),
                                event["count"], callcount, countdiff * 100,
                                realpct * 100, realpctdiff * 100,
                                onereal * 1000, onerealdiff * 100)

print "</table>"
