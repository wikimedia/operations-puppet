require 'spec_helper'

describe 'osm', :type => :class do

    context 'on Ubuntu Precise' do
        let(:facts) { {
            :lsbdistrelease => 'Precise',
            :lsbdistid      => 'Ubuntu',
        } }

        it { should contain_package('osm2pgsql').with_ensure('present') }
        it { should contain_package('osmosis').with_ensure('present') }
    end

    context 'on Debian Jessie' do
        let(:facts) { {
            :lsbdistrelease => 'Jessie',
            :lsbdistid      => 'Debian',
        } }

        it { should contain_apt__pin('osm2pgsql').with_pin('release a=jessie-backports') }
    end

end
