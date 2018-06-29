#
# cron_splay.rb
#

require 'digest/md5'

module Puppet::Parser::Functions
  newfunction(:cron_splay, :type => :rvalue, :doc => <<-EOS
Given an array of fqdn which a cron is applicable to, and a period arg which is
one of 'hourly', 'daily', 'semiweekly', or 'weekly', this sorts the fqdn set
with per-datacenter interleaving for DC-numbered hosts, splays them to fixed
even intervals within the total period, and then outputs a set of crontab time
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

Note that the semiweekly options require two separate crontab entries, using
fields suffixed with '-a' and '-b' as shown in the example below.

*Examples:*

    $times = cron_splay($hosts, 'weekly', 'foo-static-seed')
    cron { 'foo':
        minute   => $times['minute'],
        hour     => $times['hour'],
        weekday  => $times['weekday'],
    }

    # Semi-weekly operation hits every 3.5 days using dual crontab entries
    $times = cron_splay($hosts, 'semiweekly', 'bar')
    cron { 'bar-a':
        minute   => $times['minute-a'],
        hour     => $times['hour-a'],
        weekday  => $times['weekday-a'],
    }
    cron { 'bar-b':
        minute   => $times['minute-b'],
        hour     => $times['hour-b'],
        weekday  => $times['weekday-b'],
    }

    EOS
  ) do |arguments|

    unless arguments.size == 3
      raise(Puppet::ParseError, "cron_splay(): Wrong number of arguments " +
        "given (#{arguments.size} for 3)")
    end

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

    # all time values within the code are in units of minutes

    case period
    when 'hourly'
       mins = 60
    when 'daily'
       mins = 24 * 60
    when 'weekly'
       mins = 7 * 24 * 60
    when 'semiweekly'
       mins = 7 * 24 * 60
    else
      raise(Puppet::ParseError, 'cron_splay(): invalid period')
    end

    # Avoid this edge case for now.  At sufficiently large host counts and
    # small period, randomization is probably better anyways.
    if hosts.length > mins
      raise(Puppet::ParseError, 'cron_splay(): too many hosts for period')
    end

    # split hosts into N lists based the first digit of /NNNN/, defaulting to zero
    sublists = [[], [], [], [], [], [], [], [], [], []]
    hosts.each do |h|
      match = /([1-9])[0-9]{3}/.match(h)
      if match
        sublists[match[1].to_i].push(h)
      else
        sublists[0].push(h)
      end
    end

    # sort each sublist into a determinstic order based on seed
    sublists.each do |s|
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

    case period
    when 'hourly'
      output['minute'] = tval % 60
      output['hour'] = '*'
      output['weekday'] = '*'
    when 'daily'
      output['minute'] = tval % 60
      output['hour'] = (tval / 60) % 24
      output['weekday'] = '*'
    when 'weekly'
      output['minute'] = tval % 60
      output['hour'] = (tval / 60) % 24
      output['weekday'] = tval / 1440
    when 'semiweekly'
      output['minute-a'] = tval % 60
      output['hour-a'] = (tval / 60) % 24
      output['weekday-a'] = tval / 1440
      # tval2 for semiweekly is 3.5 days after tval, modulo 1w
      tval2 = (tval + (84 * 60)) % (7 * 24 * 60)
      output['minute-b'] = tval2 % 60
      output['hour-b'] = (tval2 / 60) % 24
      output['weekday-b'] = tval2 / 1440
    end

    output
  end
end

# vim: set ts=2 sw=2 et :
