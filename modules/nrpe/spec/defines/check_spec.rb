require 'spec_helper'

describe 'nrpe::check', :type => :define do
    let(:title) { 'something' }
    let(:params) { { :command => '/usr/local/bin/mycommand -i this -o that' } }

    context 'with nrpe class not defined' do
        it 'should not create /etc/nagios/nrpe.d/something.cfg' do
            should_not contain_file('/etc/nagios/nrpe.d/something.cfg')
        end
    end

    context 'with nrpe class defined' do
        let(:facts) { { :initsystem => 'systemd' } }
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
