require 'rubygems'
require 'aws-sdk'
require 'base64'
require 'digest/md5'
require 'digest/sha1'
require 'net/https'
require 'openssl'

module Jcs3

  class Deployer

    def initialize(config = {})
      @access_key_id      = config['access_key_id']
      @secret_access_key  = config['secret_access_key']
      @bucket             = config['bucket']
      @cf_distribution_id = config['cf_distribution_id']
      @dirty_keys         = Set.new

      config.each do |k, v|
        raise "Error: configuration is missing #{k}" if (%w[access_key_id secret_access_key bucket cf_distribution_id].include?(k) && v.nil?)
      end

      @s3 = AWS::S3.new(config)
    end

    def synced?(s3_key, file)
      file = File.open(file, 'r') if file.is_a? String
      file_content = file.read
      s3_object_md5 = nil

      begin
        s3_object = @s3.buckets[@bucket].objects[s3_key]
        s3_object_md5 = s3_object.etag
      rescue
        return false
      end

      my_object_md5 = md5(file_content)
      s3_object_md5.gsub('"', '') == my_object_md5
    end

    def push(s3_key, file, options = {})
      file = File.open(file, 'r') if file.is_a? String
      
      s3_object = @s3.buckets[@bucket].objects[s3_key]
      s3_object.write(file, options)

      @dirty_keys << s3_key
    end

    def invalidate_dirty_keys
      return unless @dirty_keys.length > 0
      response_code = invalidate(@dirty_keys.to_a)
      raise "Warning: Unable to invalidate keys" unless response_code == '201'
      @dirty_keys.clear if response_code == '201'
    end

    def invalidate(s3_keys)
      s3_keys = [s3_keys] if s3_keys.is_a? String

      uri = URI.parse('https://cloudfront.amazonaws.com/2010-08-01/distribution/' + @cf_distribution_id + '/invalidation')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      invalidation_response = http.request(cf_invalidation_request(s3_keys, uri))
      return invalidation_response.code
    end

    def md5(input)
      Digest::MD5.hexdigest(input)
    end

    def cf_invalidation_request(keys, uri)
      paths = '<Path>/' + keys.join('</Path><Path>/') + '</Path>'
      date = Time.now.strftime("%a, %d %b %Y %H:%M:%S %Z")

      sha1 = OpenSSL::Digest::Digest.new('sha1')
      hmac = OpenSSL::HMAC.digest(sha1, @secret_access_key, date)
      digest = Base64.encode64(hmac).strip

      req = Net::HTTP::Post.new(uri.path)
      req.initialize_http_header({
        'x-amz-date'    => date,
        'Content-Type'  => 'text/xml',
        'Authorization' => "AWS %s:%s" % [@access_key_id, digest]
      })
      req.body = "<InvalidationBatch>" + paths + "<CallerReference>ref_#{Time.now.utc.to_i}</CallerReference></InvalidationBatch>"
      req
    end

  end

end