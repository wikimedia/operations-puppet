# Puppet Success reporter
# 
#  Updates labs instance metadata with the status of the last puppet run,
#   generally 'changed' or 'failed'
require 'puppet'
require 'yaml'
require 'erb'
require 'open3'
require 'time'

Puppet::Reports.register_report(:labsstatus) do
    desc 'Log instance root passwords as they are created'

    def process
        #system("echo trying this >> /var/log/labsstatus.log")
        self.logs.each do |logline|
            if logline.message =~ /'rootpass: (.*)'/
                rootpass = $1
            end
        end
        if (!root.empty?)
            system("echo ${fqdn}: ${rootpass} >> /var/run/puppet/labspasswords")
        end
    end
end
