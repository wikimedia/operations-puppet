# normalize_level.rb
# Logstash Ruby script to build an ECS `log` field from level and syslog fields
# @version 1.0.2

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

def get_facility(field)
  # Returns normalized facility field
  unless field.nil?
    unless @facilities[field].nil?
      return [field, @facilities[field]]
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

  # bunyan sends levels as integers
  if event.get('level').is_a? Numeric
    idx = event.get('level') / 10 - 1  # transform to array index
    return @bunyan_levels[idx].upcase
  end

  if event.get('level').nil?
    if event.get('severity').nil?
      return "NOTSET"
    else
      return event.get('severity').upcase
    end
  end
  event.get('level').upcase
end

def filter(event)
  # Builds the ECS `log` field based on event `level` and `severity`
  # https://doc.wikimedia.org/ecs/#ecs-log

  # Assume ECS compliant if 'log' is a hash.
  unless event.get('log').instance_of?(Hash)
    level = get_level(event)
    severity_name, severity_code = get_severity(level)
    facility_name, facility_code = get_facility(event.get('facility'))

    event.set('log', {
      :level => level,
      :syslog => {
        :severity => {
          :code => severity_code,
          :name => severity_name
        },
        :facility => {
          :code => facility_code,
          :name => facility_name
        },
        :priority => (facility_code * 8 + severity_code) # RFC5424 (6.2.1)
      }
    })

    # Clean up migrated fields
    event.remove('severity')
    event.remove('level')
    event.remove('facility')
  end
  [event]
end
