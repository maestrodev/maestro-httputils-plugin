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

describe MaestroDev::Plugin::RestWorker do

  before(:all) do
    Maestro::MaestroWorker.mock!
  end
  
  describe "rest_get" do
    FAILURE = 404
    REJECTED = "Connection refused"
    ADDRESS = "(?:Can't|Cannot) assign requested address"
    RESOURCE = "Resource Not Found: "
    ROUTE = "No route to host"

    URL = 'sample.com/page'
    USER = 'user'
    PASSWORD = 'password'
    SERVER = "http://#{URL}"
    SERVER_AUTH = "http://#{USER}:#{PASSWORD}@#{URL}"

    before(:each) do
      @workitem = {'fields' => {
        'url' => SERVER
      }}
    end

    it "should detect missing input fields" do
      @workitem['fields'].clear

      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should include('url not specified')
    end

    it 'should not connect if service not running at host' do

      stub_request(:get, SERVER).to_raise(Errno::ECONNREFUSED)

      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should include(REJECTED)
    end

    it 'should report if host not found' do
      stub_request(:get, SERVER).to_raise(Errno::EADDRNOTAVAIL)

      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should match(ADDRESS)
    end

    it 'should report if no route to host found' do
      stub_request(:get, SERVER).to_raise(Errno::EHOSTUNREACH)

      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should include(ROUTE)
    end

    it 'should report OK if success (noauth)' do
      stub_request(:get, SERVER).to_return(:body => 'My Miss Kitty devotional page')

      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should be_nil
      @workitem['__output__'].should end_with('My Miss Kitty devotional page')
    end

    it 'should report OK if success (auth)' do
      stub_request(:get, SERVER_AUTH).to_return(:body => 'My Miss Kitty devotional page')

      @workitem['fields']['user'] = USER
      @workitem['fields']['password'] = PASSWORD
      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should be_nil
      @workitem['__output__'].should end_with('My Miss Kitty devotional page')
    end

    it 'should report if resource not found' do
      stub_request(:get, SERVER).to_return(:status => 404)

      subject.perform(:rest_get, @workitem)

      @workitem['fields']['__error__'].should include(RESOURCE)
    end
  end
    
end
