# Copyright (c) 2013 MaestroDev.  All rights reserved.
require 'maestro_plugin'
require 'rest-client'
require 'maestro_common/utils/retryable'

module MaestroDev
  class PluginError < StandardError
  end
  
  class ConfigError < PluginError
  end

  class HttpPingWorker < Maestro::MaestroWorker

    def ping_http
      write_output("\nStarting HTTP PING task...\n", :buffer => true)
      
      begin
        validate_parameters

        response = nil
        attempt = 0

        begin
          Maestro::Utils.retryable(:tries => @tries - 1,
                                   :on => Exception,
                                   :sleep => (@timeout/5)) do
  
              attempt = attempt + 1
              
              write_output("\nPinging #{@host}.  Attempt ##{attempt} of #{@tries}", :buffer => false)
              getter = RestClient::Resource.new(
                  "http://#{@host}:#{@port}/#{@web_path}",
                  :user => @ping_user,
                  :password => @ping_password,
                  :timeout => @timeout,
                  :open_timeout => @open_timeout)
  
              response = getter.get :content_type => 'application/text'
  
          end
        rescue Exception => e
          raise PluginError, "Failed to ping host/service: #{e}."
        end
  
        write_output("\nSuccessfully pinged host.", :buffer => true) if !response.nil? && response.code == 200
      rescue PluginError => e
        write_output("\n#{e.message}", :buffer => true)
        @error = e.message
      rescue Exception => e
        @error = "Error executing HTTP Ping Task: #{e.class} #{e}"
        Maestro.log.warn("Error executing HTTP Ping Task: #{e.class} #{e}: " + e.backtrace.join("\n"))
      end
  
      write_output "\n\nHTTP PING task complete\n"
      set_error(@error) if @error
    end
    
    private

    def validate_parameters
      errors = []

      @host = get_field('host', '')
      @port = intify(get_field('port'), 80)
      @web_path = get_field('web_path', '')
      @open_timeout = intify(get_field('open_timeout'), 90)
      @timeout = intify(get_field('timeout'), 90)
      @tries = intify(get_field('tries'), 5)
      @ping_user = get_field('ping_user', '')
      @ping_password = get_field('ping_password', '')

      errors << 'host not specified' if @host.empty?      
      errors << 'port not specified' if @port < 1      
      errors << 'web_path not specified' if @web_path.empty?      
      errors << 'timeout not specified' if @timeout < 1      
      errors << 'open_timeout not specified' if @open_timeout < 1      
      errors << 'tries not specified' if @open_timeout < 1      

      if !errors.empty?
        raise ConfigError, "Configuration errors: #{errors.join(', ')}"
      end
    end
    
    def intify(value, default = 0)
      res = default

      if value
        if value.is_a?(Fixnum)
          res = value
        elsif value.respond_to?(:to_i)
          res = value.to_i
        end
      end

      res
    end
  end
end