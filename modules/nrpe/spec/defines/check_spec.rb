require 'spec_helper'

describe 'nrpe::check', :type => :define do
    let(:title) { 'something' }
    let(:params) { { :command => '/usr/local/bin/mycommand -i this -o that' } }

    it do
	should contain_file('/etc/nagios/nrpe.d/something.cfg')
    end
end
