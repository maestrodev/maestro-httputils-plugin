# Copyright (c) 2013 MaestroDev.  All rights reserved.
require 'maestro_plugin'
require 'rest-client'

module MaestroDev
  module Plugin

    class RestWorker < Maestro::MaestroWorker

      def rest_get
        validate_get_parameters

        do_rest('GET') { |rest|
          rest.get(:accept => @content_type)
        }
      end

      def rest_delete
        validate_get_parameters

        do_rest('DELETE') { |rest|
          rest.delete
        }
      end

      def rest_put
        validate_put_post_parameters

        do_rest('PUT') { |rest|
          rest.put @content, :content_type => @content_type
        }
      end

      def rest_post
        validate_put_post_parameters

        do_rest('POST') { |rest|
          rest.post @content, :content_type => @content_type
        }
      end

      private

      def validate_common_parameters
        errors = []

        @url = get_field('url', '')
        @timeout = get_int_field('timeout', 90)
        @user = get_field('user', '')
        @password = get_field('password', '')
        @content_type = get_field('content_type', 'application/json')

        # If no user specified, blank user/password fields.
        if @user.empty?
          @user = nil
          @password = nil
        end

        errors << 'url not specified' if @url.empty?
        errors << 'timeout not specified' if @timeout < 1

        return errors
      end

      def validate_get_parameters
        errors = validate_common_parameters

        if !errors.empty?
          raise ConfigError, "Configuration errors: #{errors.join(', ')}"
        end
      end

      def validate_put_post_parameters
        errors = validate_common_parameters

        @content = get_field('content', '')

        if !errors.empty?
          raise ConfigError, "Configuration errors: #{errors.join(', ')}"
        end
      end

      def do_rest(operation)
        write_output("\nHTTP #{operation} #{@url}", :buffer => false)
        write_output(" with auth #{@user}:*****") if @user

        begin
          RestClient.proxy = ENV['http_proxy'] if ENV.has_key?('http_proxy')

          rest = RestClient::Resource.new(
            @url,
            :timeout => @timeout,
            :user => @user,
            :password => @password
          )
          response = yield(rest)
          write_output(" => #{response.code}\n#{response.body}")
        rescue Exception => e
          write_output("\nFAIL. #{e.class} #{e}")
          raise PluginError, e
        end
      end
    end
  end
end
