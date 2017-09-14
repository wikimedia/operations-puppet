require 'spec_helper'

describe 'base::puppet' do
    let(:pre_condition) {
        '''
        class passwords::puppet::database {}
        '''
    }
    before(:each) do
        Puppet::Parser::Functions.newfunction(:os_version, :type => :rvalue) do |args|
            TRUE
        end
    end
    it { should compile }

    context 'when auto_puppetmaster_switching is enabled' do
        before(:each) {
            Puppet::Parser::Functions.newfunction(:hiera, :type => :rvalue) do |args|
                case args[0]
                when 'auto_puppetmaster_switching'
                    return TRUE
                else
                    return args[1]
                end
            end
        }
        context 'on labs' do
            let(:facts) { { :realm => 'labs' } }
            it { should compile }
            context 'on a standalone puppetmaster' do
                let(:pre_condition) {
                    super().concat('''
                        class role::puppetmaster::standalone {}
                        include role::puppetmaster::standalone
                        ''')
                }
                it 'should fail' do
                    should compile.and_raise_error(/should only be applied on puppet clients/)
                end
            end
        end
        context 'on other realms' do
            let(:facts) { { :realm => 'some realm' } }
            it 'auto_puppetmaster_switching must not be enableable' do
                should compile.and_raise_error(/auto_puppetmaster_switching should never.*/)
            end
        end
    end
end
