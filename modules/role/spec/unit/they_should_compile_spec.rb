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

bypass_roles = [
    # Not a class but a define:
    'role::cache::instances',
    # pending_deletion
    # https://gerrit.wikimedia.org/r/#/c/301076/
    'role::mha::manager',
    'role::mha::node',
    # Deprecated
    'role::deprecated::mediawiki',
]

pending_reasons = {
    'role::analytics_cluster::hadoop::logstash' => 'Solely called by client role',

    'role::ceilometer::compute' => 'Missing ceilometer.conf.erb',
    'role::ceilometer::controller' => 'Missing ceilometer.conf.erb',

    'role::deployment::mediawiki' => 'Should be Trusty. Lacks systemd on Jessie',
    'role::deployment::server' => 'Should be Trusty. Lacks systemd on Jessie',

    'role::labs::mediawiki_vagrant' => 'Ubuntu trusty not supported by test suite',
    'role::labs::vagrant_lxc' => 'Ubuntu trusty not supported by test suite',
    'role::striker::web' => 'Ubuntu trusty not supported by test suite',

    'role::toollabs::docker::builder' => 'Package[docker-engine] not defined!',

    # Pending /manifests/role/mariadb.pp to move to a role module
    'role::labs::db::master' => 'role::mariadb::grants not under modules/',
    'role::labs::db::replica' => 'role::mariadb::grants not under modules/',
    'role::labs::db::slave' => 'role::mariadb::grants not under modules/',
    'role::labs::dns' => 'role::mariadb::grants not under modules/',

    # Classes are suffixed with '::server'
    'role::labs::openstack::designate' => 'Not in autoloader layout?',
    'role::labs::openstack::keystone' => 'Not in autoloader layout?',
    'role::labs::openstack::glance' => 'Not in autoloader layout?',
    'role::labs::openstack::nova' => 'Not in autoloader layout?',
}

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

            # Debian jessie
            :lsbdistcodename => 'jessie',
            :lsbdistid => 'Debian',
            :lsbdistrelease => '8.5',
            :operatingsystem => 'Debian',

#            # Ubuntu trusty
#            :lsbdistcodename => 'trusty',
#            :lsbdistid => 'Ubuntu',
#            :lsbdistrelease => '14.04',
#            :operatingsystem => 'Ubuntu',
#
            :mail_smarthost => ['smtp1.example.org'],
            :memorysize_mb => 1024,
            :memoryfree => '512 MB',
            :nameservers => ['127.0.0.1'],
            :processorcount => 1,
            :realm => 'production',
            :site => 'eqiad',
            :uniqueid => '00000000',
        }

        before(:each) {
            if pending_reasons.keys.include?(role_name)
                pending(pending_reasons[role_name])
            end
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
            context "On labs realm" do
                let(:facts) do
                    facts.merge({  :realm => 'labs' })
                end
                it { is_expected.to compile }
            end
        elsif role_name == 'role::lvs::balancer'
            context 'With hostname lvs1010' do
                let(:facts) do
                    facts.merge({ :hostname => 'lvs1010' })
                end
                it { is_expected.to compile }
            end
        else
            let(:facts) { facts }
            it { is_expected.to compile }
        end
    end
end
