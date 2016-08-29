require 'spec_helper'
require 'pathname'

manifests_dir = Pathname.new(File.expand_path(
        File.dirname(__FILE__) + '/../../manifests'))

# We default to 'production' realm
labs_roles = [
    'role::ci::castor::server',
    'role::ci::jenkins_access',
    'role::ci::slave::browsertests',
    'role::ci::slave::labs',
    'role::ci::slave::localbrowser',
    'role::phragile::labs',
    'role::phabricator::labs',
    'role::toollabs::clush::master',
]
labs_roles_start_with = [
    'role::labs::ores',
    'role::labs::tools',
    'role::toollabs',
]

# For role manifests that are really a define
not_class_roles = [
    'role::cache::instances',
]

pending_deletion = [
    # https://gerrit.wikimedia.org/r/#/c/301076/
    'role::mha::manager',
    'role::mha::node',
]

bypass_roles = not_class_roles + pending_deletion

Dir.glob(File.join(manifests_dir, '**/*.pp')).sort.each do |role_file|
    relative = Pathname.new(role_file).relative_path_from(manifests_dir)
    role_name = 'role::' + relative.to_s.gsub(/(\/|\.pp$)/, {'/' => '::', '\.pp' => ''})

    next if bypass_roles.include?(role_name)

    describe role_name, :type => :class do
        # mediawiki/appserver/api.yaml
        hiera_role_dir = role_name.gsub(/::/, '/')
        # mediawiki/appserver.yaml
        hiera_parent_dir = Pathname.new(hiera_role_dir).parent.to_s
        # mediawiki.yaml
        hiera_gparent_dir = Pathname.new(hiera_role_dir).parent.parent.to_s
        facts = {
            # Path for hiera lookup
            :wmf_hiera_role_dir => hiera_role_dir,
            :wmf_hiera_role_parent_dir => hiera_parent_dir,
            :wmf_hiera_role_gparent_dir => hiera_gparent_dir,
            :initsystem => 'systemd',
            :interfaces => 'eth0,lo',
            :ipaddress => '127.0.0.1',
            :ipv4 => '127.0.0.1',
            :lsbdistcodename => 'jessie',
            :lsbdistid => 'Debian',
            :lsbdistrelease => '8.5',
            :mail_smarthost => ['smtp1.example.org'],
            :memorysize_mb => 1024,
            :memoryfree => '512 MB',
            :nameservers => ['127.0.0.1'],
            :operatingsystem => 'Debian',
            :processorcount => 1,
            :realm => 'production',
            :site => 'eqiad',
            :uniqueid => '00000000',
        }

        before(:each) {
            # Per doc, accepting |args| is mandatory
            Puppet::Parser::Functions.newfunction(:secret, :type => :rvalue) { |args|
                return 'stub_secret'
            }
            Puppet::Parser::Functions.newfunction(:ipresolve, :type => :rvalue) { |args|
                return '127.0.0.1'
            }
            Puppet::Parser::Functions.newfunction(:generate, :type => :rvalue) { |args|
                return ''
            }
            Puppet::Parser::Functions.newfunction(:slice_network_constants, :type => :rvalue) { |args|
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
        if labs_roles.include?(role_name) || role_name.start_with?(*labs_roles_start_with)
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
