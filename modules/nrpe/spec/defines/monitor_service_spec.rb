require 'spec_helper'

describe 'nrpe::monitor_service', :type => :define do
    let(:title) { 'something' }
    let(:params) { {
	    :description   => 'this is a description',
	    :contact_group => 'noone',
    } }
    #let(:params) { { :command => '/usr/local/bin/mycommand -i this -o that' } }

    it do
	should contain_monitor_service('something').with(
	    :description   => 'this is a description',
	    :contact_group => 'noone',
	    :retries       => 3,
	    :ensure        => 'present',
	    :check_command => 'nrpe!check_something'
	)
    end
end
