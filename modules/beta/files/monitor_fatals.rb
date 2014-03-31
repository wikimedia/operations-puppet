#!/usr/bin/env ruby

require 'net/smtp'

fatals_file="/data/project/logs/fatal.log"

# Please also adjust the text message below
seconds_since_last_run = 12 * 60 * 60  # 12 hours

def send_email
            message = <<MESSAGE_END
From: Beta fatals <qa@lists.wikimedia.org>
To: Software quality <qa@lists.wikimedia.org>
Subject: New fatal errors on beta labs

The file at /data/project/logs/fatal.log on the deployment cluster has a
new entry within the last twelve hours.

The extensions with fatal errors:
#{@extensions_message_inclusion}

You should check it out by connecting on any instance on the beta
cluster (ie: deployment-bastion).

You can also look at logstash:

https://logstash-beta.wmflabs.org/#/dashboard/elasticsearch/fatalmonitor

MESSAGE_END

  Net::SMTP.start('mchenry.wikimedia.org') do |smtp|
    smtp.send_message message, 'qa@lists.wikimedia.org',
    'qa@lists.wikimedia.org'
  end
end

def find_problem_extensions
  @extensions_with_fatals = []
  @extensions_re = /extensions\/\w+/
  File.open(@fatals_file) do |file|
    file.each_line do |line|
      @extensions_with_fatals << @extensions_re.match(line).to_s.gsub("extensions/", "")
    end

    @extensions_with_fatals = @extensions_with_fatals.uniq
    @extensions_message_inclusion = ""
    @extensions_with_fatals.each do |ext|
      @extensions_message_inclusion << ext + "\n"
    end
  end
end

if File.exist?(@fatals_file)
  last_modified_time=File.mtime(@fatals_file)
  if Time.now.to_i - last_modified_time.to_i < seconds_since_last_run
    find_problem_extensions
    send_email
  end
end
