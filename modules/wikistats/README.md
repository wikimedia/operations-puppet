wikistats module for wikistats.wmflabs.org
a mediawiki statistics site

this sets up a site with statistics about
as many public mediawiki installs as possible
not just WMF wikis, but any mediawiki

currently it runs on instance wikistats-01

this is https://wikistats.wmflabs.org and will likely
stay a labs project forever while it has real users
results from it are used for WMF projects like
statistic tables inside Wikipedia

so if it's down it will be missed

we removed the entire SSL setup it used to have in
favor of putting it behind labs proxy and not wasting
a public IP

the matching software is in another repo:
operations/debs/wikistats

it started out as an external project to create
wiki syntax tables for pages like "List of largest wikis"
on meta and several similar ones for other projects

this is not to be confused with stats.wm by analytics
