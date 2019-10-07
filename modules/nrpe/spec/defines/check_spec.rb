require 'spec_helper'

stretch_facts = {
    # For wmflib.os_version()
    :lsbdistid      => 'Debian',
    :lsbdistrelease => '9.4',

    :initsystem => 'systemd',
}
describe 'nrpe::check', :type => :define do
    let(:title) { 'something' }
    let(:facts) {
        stretch_facts.merge({ :realm => 'production' })
    }
    let(:params) { { :command => '/usr/local/bin/mycommand -i this -o that' } }

    context 'with nrpe class not defined' do
        it 'should not create /etc/nagios/nrpe.d/something.cfg' do
            should_not contain_file('/etc/nagios/nrpe.d/something.cfg')
        end
    end

    context 'with nrpe class defined' do
        let(:facts) { {
            :initsystem => 'systemd'
        } }

        # nrpe depends on os_version which needs lsb facts to be set. However
        # facts are not set before the precondition leading os_version() to
        # fail. Mock it and make it always return true.
        before(:each) do
            Puppet::Parser::Functions.newfunction(:os_version, :type => :rvalue) { |_|
                true
            }
        end
        let(:pre_condition) { "class { 'nrpe': }" }

        it 'should create /etc/nagios/nrpe.d/something.cfg' do
            should contain_file('/etc/nagios/nrpe.d/something.cfg')
        end
    end

    context 'with ensure absent' do
        it 'should not create /etc/nagios/nrpe.d/something.cfg' do
            should_not contain_file('/etc/nagios/nrpe.d/something.cfg')
        end
    end
end
