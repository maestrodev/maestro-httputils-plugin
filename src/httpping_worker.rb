# Copyright (c) 2013 MaestroDev.  All rights reserved.
require 'maestro_plugin'
require 'rest-client'
require 'maestro_common/utils/retryable'

module MaestroDev
  module Plugin

    class HttpPingWorker < Maestro::MaestroWorker

      def ping_http
        validate_parameters

        response = nil
        attempt = 0

        RestClient.proxy = ENV['http_proxy'] if ENV.has_key?('http_proxy')

        begin
          Maestro::Utils.retryable(:tries => @tries - 1,
                                   :on => Exception,
                                   :sleep => (@timeout/@tries)) do

              attempt = attempt + 1

              write_output("\nAttempt ##{attempt} of #{@tries}.  Pinging #{@host}...", :buffer => false)

              begin
                getter = RestClient::Resource.new(
                  "http://#{@host}:#{@port}/#{@web_path}",
                  :user => @ping_user,
                  :password => @ping_password,
                  :timeout => @timeout,
                  :open_timeout => @open_timeout)

                response = getter.get :content_type => 'application/text'
              rescue Exception => e
                write_output(" FAIL. #{e}")
                raise e
              end

              write_output(" SUCCESS.\nSuccessfully pinged host.", :buffer => true)
          end
        rescue Exception => e
          raise PluginError, "Failed to ping host/service: #{e}."
        end
      end

      private

      def validate_parameters
        errors = []

        @host = get_field('host', '')
        @port = get_int_field('port', 80)
        @web_path = get_field('web_path', '')
        @open_timeout = get_int_field('open_timeout', 90)
        @timeout = get_int_field('timeout', 90)
        @tries = get_int_field('tries', 5)
        @ping_user = get_field('ping_user', '')
        @ping_password = get_field('ping_password', '')

        errors << 'host not specified' if @host.empty?
        errors << 'port not specified' if @port < 1
        errors << 'web_path not specified' if @web_path.empty?
        errors << 'timeout not specified' if @timeout < 1
        errors << 'open_timeout not specified' if @open_timeout < 1
        errors << 'tries not specified' if @tries < 1

        if !errors.empty?
          raise ConfigError, "Configuration errors: #{errors.join(', ')}"
        end
      end
    end
  end
end
