require 'net/smtp'

fatals_file="/data/project/logs/fatals.log"
seconds_since_last_run=3600

def send_email
            message = <<MESSAGE_END
From: Beta fatals <qa@lists.wikimedia.org>
To: Software quality <qa@lists.wikimedia.org>
Subject: New fatal errors on beta labs

            The file at /data/project/logs/fatal.log on the deployment cluster has a new entry within the last hour.  You should check it out.
MESSAGE_END

  Net::SMTP.start('mchenry.wikimedia.org') do |smtp|
    smtp.send_message message, 'qa@lists.wikimedia.org',
    'qa@lists.wikimedia.org'
  end
end

if File.exist?(fatals_file)
  last_modified_time=File.mtime(fatals_file)
  if Time.now.to_i - last_modified_time.to_i < seconds_since_last_run
    send_email
  end
end
