require_relative './../spec_helper'

describe 'jenkins_master' do
  it_behaves_like 'a standard Linux machine'
  it_behaves_like 'an Apache webserver'

  context 'the jenkins service' do
    describe service('docker-jenkins') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(8080) do
      it { should be_listening }
    end
  end

  context 'apache' do
    describe service('apache2') do
      it { should be_enabled }
      it { should be_running }
    end

    describe port(80) do
      it { should be_listening }
    end

    describe port(443) do
      it { should be_listening }
    end

    context 'HTTP redirects' do
      describe command("curl -kvH 'Host: ci.jenkins-ci.org' http://127.0.0.1") do
      its(:stderr) { should match 'Location: https://ci.jenkins.io/' }
      its(:exit_status) { should eq 0 }
      end
    end

    context 'Blocking bots' do
      # Bots are being redirected, booyah
      ['YisouSpider',
       'Catlight/1.8.7',
       'CheckmanJenkins (Hostname: derptown)',
      ].each do |agent|
        describe command("curl --verbose --insecure -A \"#{agent}\" -H 'Location: https://ci.jenkins.io/' --output /dev/null https://127.0.0.1/ 2>&1 | grep '302 Found'") do
          its(:exit_status) { should eql 0 }
        end
      end
    end
  end
end
