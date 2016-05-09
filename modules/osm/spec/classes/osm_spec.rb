require 'spec_helper'

describe 'osm', :type => :class do
    context 'ensure present' do
        let(:params) { {
            :ensure => 'present',
        } }

        context 'on Ubuntu Precise' do
            let(:facts) { {
                :lsbdistrelease => 'Precise',
                :lsbdistid      => 'Ubuntu',
            } }

            context 'ensure present' do
                it { should contain_package('osm2pgsql').with_ensure('present') }
                it { should contain_package('osmosis').with_ensure('present') }
            end
        end

        context 'on Debian Jessie' do
            let(:facts) { {
                :lsbdistrelease => 'Jessie',
                :lsbdistid      => 'Debian',
            } }

            context 'ensure present' do
                it { should contain_package('osm2pgsql').with_ensure('0.90.0+ds-1~bpo8+1') }
                it { should contain_package('osmosis').with_ensure('present') }
            end
        end
    end

    context 'ensure absent' do
        let(:params) { {
            :ensure => 'absent',
        } }
        let(:facts) { {
            :lsbdistrelease => 'Precise',
            :lsbdistid      => 'Ubuntu',
        } }

        it { should contain_package('osm2pgsql').with_ensure('absent') }
        it { should contain_package('osmosis').with_ensure('absent') }
    end
end
