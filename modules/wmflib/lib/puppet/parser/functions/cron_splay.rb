#
# cron_splay.rb
#

require 'digest/md5'

module Puppet::Parser::Functions
  newfunction(:cron_splay, :type => :rvalue, :doc => <<-EOS
Given an array of fqdn which a cron is applicable to, and a period arg which is
one of 'hourly', 'daily', or 'weekly', this sorts the fqdn set with
per-datacenter interleaving for DC-numbered hosts, splays them to fixed even
intervals within the total period, and then outputs a set of crontab time
fields for the fqdn currently being compiled-for.

The idea here is to ensure each host in the set executes the cron once per time
period, and also ensure the time between hosts is consistent (no edge cases
much closer than the average) by splaying them as evenly as possible with
rounding errors.  For the case of hosts with NNNN numbers indicating the
datacenter in the first digit, we also maximize the period between any two
hosts in a given datacenter by interleaving sorted per-DC lists of hosts before
splaying.

The third and final argument is a static seed which modulates the splayed
values in two different ways to minimize the effects of multiple cron_splay()
with the same hostlist and period.  It is used to select a determinstically
random "offset" for the splayed time values (so that the first host doesn't
always start at 00:00), and is also used to permute the order of the hosts
within each DC uniquely.

*Examples:*

    $times = fqdn_splay($hosts, 'weekly', 'foo-static-seed')
    cron { 'foo':
        minute   => $times['minute'],
        hour     => $times['hour'],
        weekday  => $times['weekday'],
    }

    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "cron_splay(): Wrong number of arguments " +
      "given (#{arguments.size} for 3)") if arguments.size != 3

    hosts = arguments[0]
    period = arguments[1]
    seed = arguments[2]

    unless hosts.is_a?(Array)
      raise(Puppet::ParseError, 'cron_splay(): Argument 1 must be an array')
    end

    unless period.is_a?(String)
      raise(Puppet::ParseError, 'cron_splay(): Argument 2 must be an string')
    end

    unless seed.is_a?(String)
      raise(Puppet::ParseError, 'cron_splay(): Argument 3 must be an string')
    end

    case period
    when 'hourly'
       mins = 60
    when 'daily'
       mins = 1440
    when 'weekly'
       mins = 10080
    else
      raise(Puppet::ParseError, 'cron_splay(): invalid period')
    end

    # Avoid this edge case for now.  At sufficiently large host counts and
    # small period, randomization is probably better anyways.
    if hosts.length > mins
      raise(Puppet::ParseError, 'cron_splay(): too many hosts for period')
    end

    # split hosts into N lists based the first digit of /NNNN/, defaulting to zero
    sublists = [ [], [], [], [], [], [], [], [], [], [] ]
    for h in hosts
      match = /([1-9])[0-9]{3}/.match(h)
      if match
        sublists[match[1].to_i].push(h)
      else
        sublists[0].push(h)
      end
    end

    # sort each sublist into a determinstic order based on seed
    for s in sublists
      s.sort_by! { |x| Digest::MD5.hexdigest(seed + x) }
    end

    # interleave sublists into "ordered"
    longest = sublists.max_by(&:length)
    sublists -= [longest]
    ordered = longest.zip(*sublists).flatten.compact

    # find the index of this host in ordered
    this_idx = ordered.index(lookupvar('::fqdn'))
    if this_idx.nil?
      raise(Puppet::ParseError, 'cron_splay(): this host not in set')
    end

    # find the truncated-integer splayed value of this host
    tval = this_idx * mins / ordered.length

    # use the seed (again) to add a time offset to the splayed values,
    # the time offset never being larger than the splayed interval
    tval += Digest::MD5.hexdigest(seed).to_i(16) % (mins / ordered.length)

    # generate the output
    output = {}
    output['minute'] = tval % 60

    if period == 'hourly'
      output['hour'] = '*'
    else
      output['hour'] = (tval / 60) % 24
    end

    if period == 'weekly'
      output['weekday'] = tval / 1440
    else
      output['weekday'] = '*'
    end

    return output
  end
end

# vim: set ts=2 sw=2 et :
