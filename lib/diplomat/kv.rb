require 'base64'
require 'faraday'

module Diplomat
  class Kv < Diplomat::RestClient

    attr_reader :key, :value, :raw

    # Get a value by it's key
    # @param key [String] the key
    # @return [String] The base64-decoded value associated with the key
    def get key
      @key = key
      args = ["/v1/kv/#{@key}"]
      args += check_acl_token unless check_acl_token.nil?
      @raw = @conn.get args.join
      parse_body
      return_value
    end

    # Get a value by it's key
    # @param key [String] the key
    # @param value [String] the value
    # @param options [Hash] the query params
    # @option options [Integer] :cas The modify index
    # @return [String] The base64-decoded value associated with the key
    def put key, value, options=nil
      qs = ""
      @options = options
      @raw = @conn.put do |req|
        args = ["/v1/kv/#{key}"]
        args += check_acl_token unless check_acl_token.nil?
        args += use_cas(@options) unless use_cas(@options).nil?
        req.url args.join
        req.body = value
      end
      if @raw.body == "true\n"
        @key   = key
        @value = value
      else
        @raw.body
      end
    end

    # Delete a value by it's key
    # @param key [String] the key
    # @return [nil]
    def delete key
      @key = key
      args = ["/v1/kv/#{@key}"]
      args += check_acl_token unless check_acl_token.nil?
      @raw = @conn.delete args.join
      # return_key
      # return_value
    end

    # @note This is sugar, see (#get)
    def self.get *args
      Diplomat::Kv.new.get *args
    end

    # @note This is sugar, see (#put)
    def self.put *args
      Diplomat::Kv.new.put *args
    end

    # @note This is sugar, see (#delete)
    def self.delete *args
      Diplomat::Kv.new.delete *args
    end

    private

    # Parse the body, apply it to the raw attribute
    def parse_body
      @raw = JSON.parse(@raw.body).first
    end

    # Get the key from the raw output
    def return_key
      @key = @raw["Key"]
    end

    # Get the value from the raw output
    def return_value
      @value = @raw["Value"]
      @value = Base64.decode64(@value) unless @value.nil?
    end

    def check_acl_token
      ["?token=#{Diplomat.configuration.acl_token}"] if Diplomat.configuration.acl_token
    end

    def use_cas(options)
      ["&cas=#{options[:cas]}"] if options && options[:cas]
    end
  end
end
