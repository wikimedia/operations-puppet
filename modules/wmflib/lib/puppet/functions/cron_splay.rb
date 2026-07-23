# SPDX-License-Identifier: Apache-2.0
require "digest/md5"

# @summary
#   Interleave systemd timer executions across hosts
#
# Given an array of fqdn which a cron is applicable to, and a period arg which is
# one of 'hourly', 'daily', 'semiweekly', or 'weekly', this sorts the fqdn set
# with per-datacenter interleaving for DC-numbered hosts, splays them to fixed
# even intervals within the total period, and then outputs a set of crontab time
# fields for the fqdn currently being compiled-for.

# The idea here is to ensure each host in the set executes the cron once per time
# period, and also ensure the time between hosts is consistent (no edge cases
# much closer than the average) by splaying them as evenly as possible with
# rounding errors.  For the case of hosts with NNNN numbers indicating the
# datacenter in the first digit, we also maximize the period between any two
# hosts in a given datacenter by interleaving sorted per-DC lists of hosts before
# splaying.
#
# The third and final argument is a static seed which modulates the splayed
# values in two different ways to minimize the effects of multiple cron_splay()
# with the same hostlist and period.  It is used to select a determinstically
# random "offset" for the splayed time values (so that the first host doesn't
# always start at 00:00), and is also used to permute the order of the hosts
# within each DC uniquely.
#
# Note that the semiweekly options require two separate crontab entries, using
# fields suffixed with '-a' and '-b' as shown in the example below.
#
# @example Usage
#
#    $times = cron_splay($hosts, 'weekly', 'foo-static-seed')
#    cron { 'foo':
#        minute   => $times['minute'],
#        hour     => $times['hour'],
#        weekday  => $times['weekday'],
#    }
#
#    $times = cron_splay($hosts, 'weekly', 'foo-static-seed')
#    systemd::timer::job { 'foo':
#        description       => 'foo bar',
#        command           => "/usr/local/bin/baz --foobar",
#        interval          => {'start' => 'OnCalendar', 'interval' => $times['OnCalendar']},
#        user              => 'root',
#    }
#
# @example Semi-weekly operation hits every 3.5 days using dual crontab entries
#
#    $times = cron_splay($hosts, 'semiweekly', 'bar')
#    cron { 'bar-a':
#        minute   => $times['minute-a'],
#        hour     => $times['hour-a'],
#        weekday  => $times['weekday-a'],
#    }
#    cron { 'bar-b':
#        minute   => $times['minute-b'],
#        hour     => $times['hour-b'],
#        weekday  => $times['weekday-b'],
#    }
#
Puppet::Functions.create_function(:cron_splay) do
  # @param hosts
  #   Array of fqdns to splay against, must include own host
  #
  # @param period
  #   One of 'hourly', 'daily', 'semiweekly', or 'weekly'
  #
  # @param seed
  #   Static string to modulate splay across multiple splays
  #
  # @return
  #   Hash of "minute", "hour", "weekday", and "OnCalendar"
  #
  dispatch :cron_splay do
    param "Array[String, 2]", :hosts
    param "String[1]", :period
    param "String[1]", :seed
    return_type "Hash"
  end
  def cron_splay(hosts, period, seed)
    # all time values within the code are in units of minutes

    case period
    when "hourly"
      mins = 60
    when "daily"
      mins = 24 * 60
    when "weekly"
      mins = 7 * 24 * 60
    when "semiweekly"
      mins = 7 * 24 * 60
    else
      raise(Puppet::ParseError, "cron_splay(): invalid period")
    end

    # Avoid this edge case for now.  At sufficiently large host counts and
    # small period, randomization is probably better anyways.
    if hosts.length > mins
      raise(Puppet::ParseError, "cron_splay(): too many hosts for period")
    end

    # split hosts into N lists based the first digit of /NNNN/, defaulting to zero
    sublists = [[], [], [], [], [], [], [], [], [], []]
    hosts.each do |h|
      match = /([1-9])[0-9]{3}/.match(h)
      match ? sublists[match[1].to_i].push(h) : sublists[0].push(h)
    end

    # sort each sublist into a determinstic order based on seed
    sublists.each { |s| s.sort_by! { |x| Digest::MD5.hexdigest(seed + x) } }

    # interleave sublists into "ordered"
    longest = sublists.max_by(&:length)
    sublists -= [longest]
    ordered = longest.zip(*sublists).flatten.compact

    # find the index of this host in ordered
    fqdn = closure_scope["facts"]["networking"]["fqdn"]
    this_idx = ordered.index(fqdn)
    if this_idx.nil?
      raise(Puppet::ParseError, "cron_splay(): #{fqdn} host not in set")
    end

    # find the truncated-integer splayed value of this host
    tval = this_idx * mins / ordered.length

    # use the seed (again) to add a time offset to the splayed values,
    # the time offset never being larger than the splayed interval
    tval += Digest::MD5.hexdigest(seed).to_i(16) % (mins / ordered.length)

    # generate the output
    output = {}
    tval_minute = (tval % 60).to_i
    tval_hour = ((tval / 60) % 24).to_i
    tval_dow = (tval / 1440).to_i
    dow = %w[Sun Mon Tue Wed Thu Fri Sat]
    tval_minute_s = tval_minute.to_s.rjust(2, "0")
    tval_hour_s = tval_hour.to_s.rjust(2, "0")

    case period
    when "hourly"
      output["minute"] = tval_minute
      output["hour"] = "*"
      output["weekday"] = "*"
      output["OnCalendar"] = "*-*-* *:#{tval_minute_s}:00"
    when "daily"
      output["minute"] = tval_minute
      output["hour"] = tval_hour
      output["weekday"] = "*"
      output["OnCalendar"] = "*-*-* #{tval_hour_s}:#{tval_minute_s}:00"
    when "weekly"
      output["minute"] = tval_minute
      output["hour"] = tval_hour
      output["weekday"] = tval_dow
      output[
        "OnCalendar"
      ] = "#{dow[tval_dow]} *-*-* #{tval_hour_s}:#{tval_minute_s}:00"
    when "semiweekly"
      output["minute-a"] = tval_minute
      output["hour-a"] = tval_hour
      output["weekday-a"] = tval_dow
      output[
        "OnCalendar-a"
      ] = "#{dow[tval_dow]} *-*-* #{tval_hour_s}:#{tval_minute_s}:00"
      # tval2 for semiweekly is 3.5 days after tval, modulo 1w
      tval2 = (tval + (84 * 60)) % (7 * 24 * 60)
      tval2_minute = (tval2 % 60).to_i
      tval2_hour = ((tval2 / 60) % 24).to_i
      tval2_dow = (tval2 / 1440).to_i
      tval2_minute_s = tval2_minute.to_s.rjust(2, "0")
      tval2_hour_s = tval2_hour.to_s.rjust(2, "0")
      output["minute-b"] = tval2_minute
      output["hour-b"] = tval2_hour
      output["weekday-b"] = tval2_dow
      output[
        "OnCalendar-b"
      ] = "#{dow[tval2_dow]} *-*-* #{tval2_hour_s}:#{tval2_minute_s}:00"
    end

    output
  end
end

# vim: set ts=2 sw=2 et :
