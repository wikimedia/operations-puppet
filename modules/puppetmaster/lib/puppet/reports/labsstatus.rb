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
    desc 'Record puppet status of labs instances in labs instance metadata'

    def addMeta(conf, project, host, key, value)
            command = "/usr/bin/nova --no-cache --os-region-name #{conf['region']} --os-auth-url #{conf['auth_url']} --os-password #{conf['password']} --os-username #{conf['username']} --os-tenant-name #{project} meta #{host} set #{key}=#{value}"
            system("echo trying \"#{command}\" >> /var/log/labsstatus.log")

            stdin, stdout, stderr, wait_thr = Open3.popen3(command)
            std_out = stdout.read
            std_err = stderr.read
            stdin.close
            stdout.close
            stderr.close
            insp = std_err.inspect
            system("echo insp: #{insp} >> /var/log/labsstatus.log")
    end

    def process
        system("echo trying this >> /var/log/labsstatus.log")
        project = ""
        hostname = ""
        conf = YAML.load_file('/etc/labsstatus.cfg')
        self.logs.each do |logline|
            if logline.message =~ /'instanceproject: (.*)'/
                project = $1
            end
            if logline.message =~ /'hostname: (.*)'/
                hostname = $1
            end
        end
        if (!project.empty?) and (!hostname.empty?)
            self.addMeta(conf, project, hostname, 'puppetstatus', self.status)
            self.addMeta(conf, project, hostname, 'puppettimestamp', Time.new.to_i)
        end
    end
end
