[![Build Status](https://travis-ci.org/dalen/puppet-puppetdbquery.png)](https://travis-ci.org/dalen/puppet-puppetdbquery)

PuppetDB query tools
====================

This module implements command line tools and Puppet functions that can be used to query puppetdb.
There's also a hiera backend that can be used to return query results from puppetdb.

Usage warning
-------------

You might not need this puppet module anymore. PuppetDB bundles a simplified query language since version 4.0. So unless you really prefer the syntax in this module you can just use PQL instead. See https://puppet.com/blog/introducing-puppet-query-language-pql for more details.

Requirements
============

PuppetDB terminus is required for the Puppet functions, but not for the face.

To parse date queries the Ruby gem "chronic" is required.

Required PuppetDB version
-------------------------

This module uses the V4 API, and as such it requires at least PuppetDB 3.0.0.
If you are using PuppetDB 2.x please use the 1.x version of this module instead.

Query syntax
============

Use `fact=value` to search for nodes where `fact` equals `value`. To search for
structured facts use dots between each part of the fact path, for example
`foo.bar=baz`.

Resources can be matched using the syntax `type[title]{param=value}`.
The part in brackets is optional. You can also specify `~` before the `title`
to do a regexp match on the title. Type names and class names are case insensitive.
A resource can be preceded by @@ to match exported resources, the default is to only
match "local" resources.

Strings can contain letters, numbers or the characters :-_ without needing to be quoted.
If they contain any other characters they need to be quoted with single or double quotes.
Use backslash (\) to escape quotes within a quoted string or double backslash for backslashes.

An unquoted number or the strings true/false will be interpreted as numbers and boolean
values, use quotation marks around them to search for them as strings instead.

A @ sign before a string causes it to be interpreted as a date parsed with
[chronic](https://github.com/mojombo/chronic). For example `@"2 hours ago"`.

A # sign can be used to do a subquery, against the nodes endpoint for example to
query the `report_timestamp`, `catalog_timestamp` or `facts_timestamp` fields.
For example `#node.report_timestamp < @"2 hours ago"`.

A subquery using the # sign can have a block of expressions instead of a single
expression. For example `#node { report_timestamp > @"4 hours ago" and
report_timestamp < @"2 hours ago" }`

A bare string without comparison operator will be treated as a regexp match against the certname.

#### Comparison operators

| Op | Meaning                |
|----|------------------------|
| =  | Equality               |
| != | Not equal              |
| ~  | Regexp match           |
| !~ | Not equal Regexp match |
| <  | Less than              |
| =< | Less than or equal     |
| >  | Greater than           |
| => | Greater than or equal  |

#### Logical operators

| Op  |            |
|-----|------------|
| not | (unary op) |
| and |            |
| or  |            |

Shown in precedence order from highest to lowest. Use parenthesis to change order in an expression.

### Query Examples

Nodes with package mysql-server and amd64 arcitecture

    (package["mysql-server"] and architecture=amd64)

Nodes with the class Postgresql::Server and a version set to 9.3

    class[postgresql::server]{version=9.3}

Nodes with 4 or 8 processors running Linux

    (processorcount=4 or processorcount=8) and kernel=Linux

Nodes that haven't reported in the last 2 hours

    #node.report_timestamp<@"2 hours ago"

Usage
======

To get a list of the supported subcommands for the puppetdbquery face, run:

     $ puppet help puppetdbquery

You can run `puppet help` on the returned subcommands

    $ puppet help puppetdbquery nodes
    $ puppet help puppetdbquery facts

CLI
---

Each of the faces uses the following query syntax to return all objects found on a subset of nodes:

    # get all nodes that contain the apache package and are in france, or all nodes in the us
    $ puppet puppetdbquery nodes '(Package[httpd] and country=fr) or country=us'

Each of the individual faces returns a different data format:

nodes - a list of nodes identified by a name

     $ puppet puppetdbquery nodes '(Package["mysql-server"] and architecture=amd64)'
       ["db_node_1", "db_node2"]

facts - a hash of facts per node

     $ puppet puppetdbquery facts '(Package["mysql-server"] and architecture=amd64)'
       db_node_1  {"facterversion":"1.6.9","hostname":"controller",...........}
       db_node_2  {"facterversion":"1.6.9","hostname":"controller",...........}

events - a list of events on the matched nodes

     $ puppet puppetdbquery events '(Package["mysql-server"] and architecture=amd64)' --since='1 hour ago' --until=now --status=success
       host.example.com: 2013-06-10T10:58:37.000Z: File[/foo/bar]/content ({md5}5711edf5f5c50bd7845465471d8d39f0 -> {md5}e485e731570b8370f19a2a40489cc24b): content changed '{md5}5711edf5f5c50bd7845465471d8d39f0' to '{md5}e485e731570b8370f19a2a40489cc24b'

Ruby
----

  faces can be called from the ruby in exactly they same way they are called from the command line:

    $ irb> require 'puppet/face'
      irb> Puppet.initialize_settings
      irb> Puppet::Face[:query, :current].nodes('(Package["mysql-server"] and architecture=amd64)')

Puppet functions
----------------

There's corresponding functions to query PuppetDB directly from Puppet manifests.
All the functions accept either the simplified query language or raw PuppetDB API queries.

### query_nodes

Accepts two arguments, a query used to discover nodes, and a optional
fact that should be returned.

Returns an array of certnames or fact values if a fact is specified.

#### Examples

    $hosts = query_nodes('manufacturer~"Dell.*" and processorcount=24 and Class[Apache]')

    $hostips = query_nodes('manufacturer~"Dell.*" and processorcount=24 and Class[Apache]', 'ipaddress')

### query_resources

Accepts two arguments or three argument, a query used to discover nodes, and a resource query
, and an optional a boolean to whether or not to group the result per host.


Return either a hash (by default) that maps the name of the nodes to a list of
resource entries.  This is a list because there's no single
reliable key for resource operations that's of any use to the end user.

#### Examples

Returns the parameters and such for the ntp class for all CentOS nodes:

    $resources = query_resources('Class["apache"]{ port = 443 }', 'User["apache"]')

Returns the parameters for the apache class for all nodes in a flat array:

    query_resources(false, 'Class["apache"]', false)

### query_facts

Similar to query_nodes but takes two arguments, the first is a query used to discover nodes, the second is a list of facts to return for those nodes.

Returns a nested hash where the keys are the certnames of the nodes, each containing a hash with facts and fact values.

#### Example

    query_facts('Class[Apache]{port=443}', ['osfamily', 'ipaddress'])

Example return value in JSON format:

    {
      "foo.example.com": {
        "ipaddress": "192.168.0.2",
        "osfamily": "Redhat"
      },
      "bar.example.com": {
        "ipaddress": "192.168.0.3",
        "osfamily": "Debian"
      }
    }

### Querying nested facts

Facter 3 introduced many nested facts, so puppetdbquery provides an easy way to query for a value nested within a fact that's a hash.
To query for a nested value, simply join the keys you want to extract together on periods, like so:

#### Example

    $host_eth0_networks = query_nodes('manufacturer~"Dell.*" and Class[Apache]', 'networking.interfaces.eth0.network')

    $host_kernels_and_ips = query_facts('manufacturer~"Dell.*" and Class[Apache]', ['kernel', 'networking.interfaces.eth1.ip'])

Hiera backend
-------------

The hiera backend can be used to return an array with results from a puppetdb query. It requires another hiera backend to be active at the same time, and that will be used to define the actual puppetdb query to be used. It does not matter which backend that is, there can even be several of them. To enable add the backend `puppetdb`to the backends list in `hiera.yaml`.

### hiera 3

```yaml
---
:backends:
  - yaml
  - puppetdb
```

### hiera 5

```yaml
---
version: 5

hierarchy:
  - name: Puppetdb
    lookup_key: puppetdb_lookup_key
```

### Note: hiera 5 is not backward compatible

You can not use the hiera 3 backed at all in hiera 5. Backwards compatibility is broken.
You must switch to hiera 5 config to use this in hiera 5.

### Examples

So instead of writing something like this in for example your `hiera-data/common.yaml`:

    ntp::servers:
      - 'ntp1.example.com'
      - 'ntp2.example.com'

You can now instead write:

    ntp::servers::_nodequery: 'Class[Ntp::Server]'

It will then find all nodes with the class ntp::server and return an array containing their certname. If you instead want to return the value of a fact, for example the `ipaddress`, the nodequery can be a tuple, like:

    ntp::servers::_nodequery: ['Class[Ntp::Server]', 'ipaddress']

or a hash:

    ntp::servers::_nodequery:
      query: 'Class[Ntp::Server]'
      fact: 'ipaddress'

Sometimes puppetdb doesn't return items in the same order every run - hiera 5 only:

    ntp::servers::_nodequery: ['Class[Ntp::Server]', 'ipaddress', true]

    ntp::servers::_nodequery:
      query: 'Class[Ntp::Server]'
      fact: 'ipaddress'
      sort: true

When returning facts only nodes that actually have the fact are returned, even if more nodes would in fact match the query itself.

Related projects
================

* JavaScript version: https://github.com/dalen/node-puppetdbquery
* Python version: https://github.com/bootc/pypuppetdbquery
