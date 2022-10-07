# SPDX-License-Identifier: Apache-2.0
# normalize_level.rb
# Logstash Ruby script to populate `log.level` and `log.syslog` based on indicators in other fields
# @version 1.0.4

def register(*)
  # RFC5424 severity to supported level field mapping
  # see get_severity() below
  @severity_map = {
    "emergency" => {
      :aliases => ["emerg", "fatal"],
      :code => 0
    },
    "alert" => {
      :aliases => [],
      :code => 1
    },
    "critical" => {
      :aliases => ["crit"],
      :code => 2
    },
    "error" => {
      :aliases => ["err"],
      :code => 3
    },
    "warning" => {
      :aliases => ["warn"],
      :code => 4
    },
    "notice" => {
      :aliases => [],
      :code => 5
    },
    "informational" => {
      :aliases => ["info"],
      :code => 6
    },
    "debug" => {
      :aliases => ["trace"],
      :code => 7
    },
  }

  # https://github.com/trentm/node-bunyan#levels
  @bunyan_levels = [
    "trace", # 10
    "debug", # 20
    "info",  # 30
    "warn",  # 40
    "error", # 50
    "fatal"  # 60
  ]

  @facilities = {
    "kernel"   => 0,
    "user"     => 1,
    "mail"     => 2,
    "daemon"   => 3,
    "auth"     => 4,
    "syslog"   => 5,
    "lpr"      => 6,
    "news"     => 7,
    "uucp"     => 8,
    "cron"     => 9,
    "authpriv" => 10,
    "ftp"      => 11,
    "aso"      => 12,
    "caa"      => 13,
    # no string representation for 14/15
    # https://github.com/rsyslog/rsyslog/blob/master/runtime/rsyslog.h
    # https://github.com/rsyslog/rsyslog/blob/master/runtime/srutils.c
    "local0"   => 16,
    "local1"   => 17,
    "local2"   => 18,
    "local3"   => 19,
    "local4"   => 20,
    "local5"   => 21,
    "local6"   => 22,
    "local7"   => 23
  }
end

def get_facility(event)
  # Returns normalized facility field

  facility = [
    event.get('[rsyslog][facility]'),
    event.get('facility'),
  ].find(-> { return 'local7' }) { |v| !v.nil? }

  unless facility.nil?
    unless @facilities[facility].nil?
      return [facility, @facilities[facility]]
    end
  end
  ["local7", 23]
end

def get_severity(field)
  # Returns normalized severity field
  # Defaults to alert because this severity level is seldom hit.
  # Mismatches between `log.syslog.severity` and `log.level` should be addressed
  # Default ["alert", 1]
  unless field.nil?
    field = field.downcase
    @severity_map.each do |k, v|
      if (v[:aliases] + [k]).include?(field)
        return k, v[:code]
      end
    end
  end
  ["alert", 1]
end

def get_level(event)
  # Returns normalized level field.
  # dependent on the availability of either `event.level` or `event.severity`

  level = [
    event.get('[log][level]'),
    event.get('level'),
    event.get('[rsyslog][severity]'),
    event.get('severity'),
  ].find(-> { return 'NOTSET' }) { |v| !v.nil? }

  # bunyan sends levels as integers
  if level.is_a? Numeric
    idx = level / 10 - 1  # transform to array index
    level = @bunyan_levels[idx]
  end

  level.upcase
end

def filter(event)
  original_log = event.get('log')

  # move original log field out of the way, but still reachable in case we need it
  unless original_log.instance_of? Hash || original_log.nil?
    event.set('_log', original_log)
    event.remove('log')
  end

  level = get_level(event)
  severity_name, severity_code = get_severity(level)
  facility_name, facility_code = get_facility(event)

  event.set('[log][level]', level)

  unless level == 'NOTSET'
    event.set('[log][syslog]', {
      :severity => {
        :code => severity_code,
        :name => severity_name
      },
      :facility => {
        :code => facility_code,
        :name => facility_name
      },
      :priority => (facility_code * 8 + severity_code) # RFC5424 (6.2.1)
    })
  end

  # Clean up migrated fields
  event.remove('severity')
  event.remove('level')
  event.remove('facility')
  [event]
end
