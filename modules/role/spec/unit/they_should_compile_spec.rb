require 'spec_helper'
require 'pathname'

manifests_dir = Pathname.new(
    File.expand_path(
        File.dirname(__FILE__) + '/../../manifests'))


Dir.glob(File.join(manifests_dir, '**/*.pp')).sort.each do |role_file|
    relative = Pathname.new(role_file).relative_path_from(manifests_dir)
    role_name = 'role::' + relative.to_s.gsub(/(\/|\.pp$)/, {'/' => '::', '\.pp' => ''})

    describe role_name, :type => :class do
        let(:facts) { {
            # Path for hiera lookup
            :wmf_hiera_role_dir => role_name.gsub(/::/, '/'),
            :uniqueid => '00000000',
            :realm => 'production',
            :ipaddress => '127.0.0.1',
            :ipv4 => '127.0.0.1',
            :initsystem => 'systemd',
            :nameservers => ['127.0.0.1'],
            :operatingsystem => 'Debian',
            :lsbdistrelease => '8.5',
            :lsbdistid => 'Debian',
            :processorcount => 1,
        } }

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
        }
        it { is_expected.to compile }
    end
end
