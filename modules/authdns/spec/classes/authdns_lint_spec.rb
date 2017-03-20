require 'integration_helper'
require 'pry'

describe 'authdns::config' do

    let(:facts) { {
        :lsbdistrelease => '8.6',
        :lsbdistid => 'Debian',
        :operatingsystem => 'Debian',
        # For udp_threads / tcp_threads
        :physicalcorecount => 4,
    } }

    hiera = Hiera.new(
        :config => 'spec/fixtures/hiera.yaml'
    )
    let(:params) { {
        :lvs_services => hiera.lookup('lvs::configuration::lvs_services', nil, {}),
        :discovery_services => hiera.lookup('discovery::services', nil, {}),
    } }

    it {
        conf_dir = Dir.mktmpdir
        begin
            catalogue.resources.each { |res|
                next unless res.type == 'File'
                next unless res.include? 'content'
                f_name = File.join(conf_dir, res['path'])
                FileUtils.mkdir_p File.dirname(f_name)
                f = File.new(f_name, 'w')
                f.write(res['content'])
                f.close
            }
            gdnsd_checkconf = system('gdnsd', '-sSc', "#{conf_dir}/srv/authdns/staging-puppet/etc", 'checkconf')
            expect(gdnsd_checkconf).to be true
        ensure
            if ENV['JENKINS_URL']
                log_dest = File.join(ENV['WORKSPACE'], 'logs', 'authdns-etc')
                FileUtils.mkdir_p log_dest
                FileUtils.cp_r conf_dir log_dest
            end
            FileUtils.remove_entry conf_dir
        end
    }
end
