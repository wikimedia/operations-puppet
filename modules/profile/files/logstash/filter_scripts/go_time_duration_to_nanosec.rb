# SPDX-License-Identifier: Apache-2.0
# go_time_duration_to_nanosec.rb
# Logstash Ruby script to convert Go time.Duration strings to nanoseconds
# @version: 1.0.0

def register(params)
  @source = params["source"]
  @target = params["target"]

  @units = {
    "ns" => 1,
    "us" => 1_000,
    "µs" => 1_000,
    "ms" => 1_000_000,
    "s"  => 1_000_000_000,
    "m"  => 60 * 1_000_000_000,
    "h"  => 3600 * 1_000_000_000
  }.freeze

  # \G: It initially matches the beginning of subject,
  # and in each following iteration it matches where the last match finished.
  @token_re = /\G(-?(?:\d+(?:\.\d*)?))(ns|us|µs|ms|s|m|h)/
end

def parse_decimal_to_ns(value_str, multiplier)
  value_str = value_str.sub("-", "")

  int_part, frac_part = value_str.split(".")

  ns = int_part.to_i * multiplier

  if frac_part
    frac_multiplier = multiplier / (10**frac_part.length)
    ns += frac_part.to_i * frac_multiplier
  end

  ns
end

def filter(event)
  duration = event.get(@source).to_s.strip

  negative = duration.start_with?("-")

  i = 0
  n = duration.length
  total = 0

  while i < n
    match = @token_re.match(duration, i)
    unless match
      event.tag('_go_time_duration_to_nanosec_parse_failure')
      break
    end

    value = match[1]
    unit  = match[2]

    multiplier = @units[unit]
    unless multiplier
      event.tag('_go_time_duration_to_nanosec_unknown_unit')
      break
    end

    total += parse_decimal_to_ns(value, multiplier)
    i = match.end(0)
  end

  event.set(@target, negative ? -total : total)

  [event]
end

if __FILE__ == $PROGRAM_NAME
  require_relative '../helpers/filter_scripts_test_helper'
  require 'date_core'

  register({
    'source' => '[labels][response_time]',
    'target' => '[process][uptime]'
  })

  fixtures = [
    {'labels' => {
      'response_time' => "0s",
      'expected_process_uptime' => 0
      }
    },
    {'labels' => {
      'response_time' => "1ns",
      'expected_process_uptime' => 1
      }
    },
    {'labels' => {
      'response_time' => "1.1µs",
      'expected_process_uptime' => 1_100
      }
    },
    {'labels' => {
      'response_time' => "1.1us",
      'expected_process_uptime' => 1_100
      }
    },
    {'labels' => {
      'response_time' => "2.2ms",
      'expected_process_uptime' => 2_200_000
      }
    },
    {'labels' => {
      'response_time' => "3.3s",
      'expected_process_uptime' => 3_300_000_000
      }
    },
    {'labels' => {
      'response_time' => "4m5s",
      'expected_process_uptime' => 245_000_000_000
      }
    },
    {'labels' => {
      'response_time' => "4m5.001s",
      'expected_process_uptime' => 245_001_000_000
      }
    },
    {'labels' => {
      'response_time' => "5h6m7.001s",
      'expected_process_uptime' => 18_367_001_000_000
      }
    },
    {'labels' => {
      'response_time' => "8m0.000000001s",
      'expected_process_uptime' => 480_000_000_001
      }
    },
    {'labels' => {
      'response_time' => "2562047h47m16.854775808s",
      'expected_process_uptime' => 9_223_372_036_854_775_808
      }
    },
    {'labels' => {
      'response_time' => "-2562047h47m16.854775808s",
      'expected_process_uptime' => -9_223_372_036_854_775_808
      }
    }
  ]

  fixtures.each do |fixture|
    event = filter(Event.new(fixture))[0]
    if ARGV[0] == 'debug'
      require 'json'
      puts(JSON.pretty_generate(event.to_hash))
    end
    assert_true(
      "[process][uptime] matches the expected value",
      event.get('[process][uptime]') == event.get('[labels][expected_process_uptime]')
    )
  end
end
