#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'aws-sdk-cognitoidentityprovider'
require 'base64'
require 'openssl'
require 'json'
require 'io/console'
require 'time'

REGION = ENV.fetch('AWS_REGION', 'us-east-1').freeze
CLIENT_ID = ENV.fetch('COGNITO_CLIENT_ID')
CLIENT_SECRET = ENV['COGNITO_CLIENT_SECRET']

if CLIENT_SECRET.to_s.empty?
  abort 'COGNITO_CLIENT_SECRET ausente; no se puede calcular SECRET_HASH.'
end

puts '\n== Cognito token generator ==\n'
print 'Username: '
username = STDIN.gets&.strip

print 'Password: '
password = STDIN.noecho(&:gets)&.strip
puts

if username.to_s.empty? || password.to_s.empty?
  abort 'Username y password son obligatorios.'
end

secret_hash = Base64.strict_encode64(
  OpenSSL::HMAC.digest('sha256', CLIENT_SECRET, username + CLIENT_ID)
)

client = Aws::CognitoIdentityProvider::Client.new(region: REGION)

resp = client.initiate_auth(
  client_id: CLIENT_ID,
  auth_flow: 'USER_PASSWORD_AUTH',
  auth_parameters: {
    'USERNAME' => username,
    'PASSWORD' => password,
    'SECRET_HASH' => secret_hash
  }
)

result = resp.authentication_result

output = {
  issued_at: Time.now.utc.iso8601,
  expires_in: result.expires_in,
  access_token: result.access_token,
  id_token: result.id_token,
  refresh_token: result.refresh_token
}

puts '\nTokens:'
puts JSON.pretty_generate(output)
