require 'spec_helper'

describe 'nrpe::monitor_service', :type => :define do
    let(:title) { 'something' }
    let(:params) do {
        :description   => 'this is a description',
        :contact_group => 'none',
        :nrpe_command  => '/usr/local/bin/mycommand -i this -o that',
        }
    end

    it do
        should contain_nrpe__check('check_something').with(
            :command       => '/usr/local/bin/mycommand -i this -o that',
            :ensure        => 'present'
        )
    end
    it do
        should contain_monitor_service('something').with(
            :description   => 'this is a description',
            :contact_group => 'none',
            :retries       => 3,
            :ensure        => 'present',
            :check_command => 'nrpe!check_something'
        )
    end
end
