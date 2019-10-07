require 'spec_helper'

stretch_facts = {
    # For wmflib.os_version()
    :lsbdistid      => 'Debian',
    :lsbdistrelease => '9.4',

    :initsystem => 'systemd',
}
describe 'nrpe::monitor_service', :type => :define do
    let(:title) { 'something' }
    let(:facts) {
        stretch_facts.merge({ :realm => 'production' })
    }

    context 'with ensure present' do
      let(:params) do {
          :description   => 'this is a description',
          :contact_group => 'none',
          :nrpe_command  => '/usr/local/bin/mycommand -i this -o that',
          :critical      => false,
          :timeout       => 42,
          :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
          }
      end

      it 'contains normal resources' do
          should contain_nrpe__check('check_something').with(
              :command       => '/usr/local/bin/mycommand -i this -o that',
              :ensure        => 'present'
          )
          should contain_monitoring__service('something').with(
              :description   => 'this is a description',
              :contact_group => 'none',
              :retries       => 3,
              :ensure        => 'present',
              :check_command => 'nrpe_check!check_something!42',
              :critical      => false,
              :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
          )
      end
    end

    context 'with ensure present, description missing' do
      let(:params) do {
          :nrpe_command  => '/usr/local/bin/mycommand -i this -o that',
          :contact_group => 'none',
          :critical      => false,
          :timeout       => 42,
          :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
          }
      end
      it 'does not compile' do
        should_not compile
      end
    end

    context 'with ensure present, nrpe_command missing' do
      let(:params) do {
          :description   => 'none',
          :contact_group => 'none',
          :critical      => false,
          :timeout       => 42,
          :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
          }
      end
      it 'does not compile' do
        should_not compile
      end
    end

    context 'with ensure absent, nrpe_command missing' do
      let(:params) do {
          :description   => 'foobar',
          :contact_group => 'none',
          :critical      => false,
          :timeout       => 42,
          :ensure        => 'absent',
          :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
          }
      end
      it 'absents resources' do
        should compile
        should compile
        should contain_nrpe__check('check_something').with(
            :ensure        => 'absent'
        )
        should contain_monitoring__service('something').with(
            :contact_group => 'none',
            :retries       => 3,
            :ensure        => 'absent',
            :description   => 'foobar',
            :critical      => false,
            :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
        )
      end
    end

    context 'with ensure absent, description missing' do
      let(:params) do {
          :nrpe_command  => '/usr/local/bin/mycommand -i this -o that',
          :contact_group => 'none',
          :critical      => false,
          :timeout       => 42,
          :ensure        => 'absent',
          :notes_url     => 'https://wikitech.wikimedia.org/wiki/Monitoring'
          }
      end
      it 'absents resources' do
        should compile
        should contain_nrpe__check('check_something').with(
            :command       => '/usr/local/bin/mycommand -i this -o that',
            :ensure        => 'absent'
        )
        should contain_monitoring__service('something').with(
            :contact_group => 'none',
            :retries       => 3,
            :ensure        => 'absent',
            :check_command => 'nrpe_check!check_something!42',
            :critical      => false
        )
      end
    end
end
