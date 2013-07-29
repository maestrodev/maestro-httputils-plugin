# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#  http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe MaestroDev::Plugin::HttpPingWorker do

  before(:all) do
    Maestro::MaestroWorker.mock!
  end
  
  describe "ping_http()" do

    SUCCESS = "Successfully pinged host."
    FAILURE = 404
    REJECTED = "Failed to ping host/service: Connection refused"
    UNKNOWN = "Failed to ping host/service"
    RESOURCE = "Resource Not Found: "
    ROUTE = "Failed to ping host/service: No route to host"

    HOST = 'localhost'
    PORT = 22
    USER = 'tomcat'
    PASSWORD = 'tomcat'
    WEB_PATH = '/centrepoint'
    TIMEOUT = 5
    OPEN_TIMEOUT = 5
    
    before(:each) do
      @workitem = {'fields' => {
        'host' => HOST,
        'port' => PORT,
        'ping_user' => USER,
        'ping_password' => PASSWORD,
        'web_path' => WEB_PATH,
        'timeout' => TIMEOUT,
        'open_timeout' => OPEN_TIMEOUT
      }}
    end

    it "should detect missing input fields" do
      @workitem['fields'].clear

      subject.perform(:ping_http, @workitem)

      @workitem['fields']['__error__'].should include("host not specified")
      @workitem['fields']['__error__'].should include("web_path not specified")
    end

    it 'should not connect if service not running at host' do

      stub_request(:get, "http://#{USER}:#{PASSWORD}@#{HOST}:#{PORT}/#{WEB_PATH}").to_raise(Errno::ECONNREFUSED)

      subject.perform(:ping_http, @workitem)

      @workitem['fields']['__error__'].should include(REJECTED)
    end


    it 'should report if host not found' do
      stub_request(:get, "http://#{USER}:#{PASSWORD}@#{HOST}:#{PORT}/#{WEB_PATH}").to_raise(Errno::EADDRNOTAVAIL)

      subject.perform(:ping_http, @workitem)

      @workitem['fields']['__error__'].should include(UNKNOWN)
    end

    it 'should report if no route to host found' do
      stub_request(:get, "http://#{USER}:#{PASSWORD}@#{HOST}:#{PORT}/#{WEB_PATH}").to_raise(Errno::EHOSTUNREACH)

      subject.perform(:ping_http, @workitem)

      @workitem['fields']['__error__'].should include(ROUTE)
    end

    it 'should report OK if service found' do
      stub_request(:get, "http://#{USER}:#{PASSWORD}@#{HOST}:#{PORT}/#{WEB_PATH}").to_return(:body => 'My Miss Kitty devotional page')

      subject.perform(:ping_http, @workitem)

      @workitem['fields']['__error__'].should be_nil
      @workitem['__output__'].should include(SUCCESS)

    end

    it 'should report if resource not found' do
      stub_request(:get, "http://#{USER}:#{PASSWORD}@#{HOST}:#{PORT}/#{WEB_PATH}").to_return(:status => 404)

      subject.perform(:ping_http, @workitem)

      @workitem['fields']['__error__'].should include(RESOURCE)
    end
  end
    
end
