require 'spec_helper'
require 'pathname'

manifests_dir = Pathname.new(File.expand_path(
        File.dirname(__FILE__) + '/../../manifests'))

# We default to 'production' realm
labs_only_roles = [
    'role::ci::castor::server',
    'role::ci::jenkins_access',
    'role::ci::slave::browsertests',
    'role::ci::slave::labs',
    'role::ci::slave::localbrowser',
]

Dir.glob(File.join(manifests_dir, '**/*.pp')).sort.each do |role_file|
    relative = Pathname.new(role_file).relative_path_from(manifests_dir)
    role_name = 'role::' + relative.to_s.gsub(/(\/|\.pp$)/, {'/' => '::', '\.pp' => ''})

    describe role_name, :type => :class do
        facts = {
            # Path for hiera lookup
            :wmf_hiera_role_dir => role_name.gsub(/::/, '/'),

            :initsystem => 'systemd',
            :interfaces => 'eth0,lo',
            :ipaddress => '127.0.0.1',
            :ipv4 => '127.0.0.1',
            :lsbdistid => 'Debian',
            :lsbdistrelease => '8.5',
            :mail_smarthost => ['smtp1.example.org'],
            :memorysize_mb => 1024,
            :nameservers => ['127.0.0.1'],
            :operatingsystem => 'Debian',
            :processorcount => 1,
            :realm => 'production',
            :site => 'eqiad',
            :uniqueid => '00000000',
        }

        before(:each) {
            Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |args|
                return ''
            }
            Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |args|
                return ''
            }
            Puppet::Parser::Functions.newfunction(:generate, :type => :rvalue) { |args|
                return ''
            }
            Puppet::Parser::Functions.newfunction(:kafka_config, :type => :rvalue) { |args|
                return {
                    'name' => 'fake_kafka_cluster',
                    'brokers' => {
                        'string' => '',
                        'array' => [],
                    },
                    'zookeeper' => {
                        'url' => '',
                        'hosts' => [],
                    }
                }
            }
        }
        if labs_only_roles.include?(role_name)
            describe "On labs realm" do
                let(:facts) do
                    facts.merge({  :realm => 'labs' })
                end
                it { is_expected.to compile }
            end
        else
            let(:facts) { facts }
            it { is_expected.to compile }
        end
    end
end
