#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'aws-sdk-cognitoidentityprovider'
require 'json'
require 'net/http'
require 'securerandom'
require 'uri'

API_BASE_URL = ENV.fetch('API_BASE_URL', 'http://localhost:3000').chomp('/').freeze
AWS_REGION = ENV.fetch('AWS_REGION', 'us-east-1').freeze
USER_POOL_ID = ENV['COGNITO_USER_POOL_ID']

if USER_POOL_ID.to_s.empty?
  abort 'Missing COGNITO_USER_POOL_ID. Load your environment (e.g. `source .env`) before running.'
end

puts '\n== Cognito JWT API quick test ==\n'

def ask(prompt, default = nil)
  print default ? "#{prompt} [#{default}]: " : "#{prompt}: "
  value = STDIN.gets&.strip
  value = nil if value&.empty?
  value || default
end

def build_uri(path)
  URI.parse("#{API_BASE_URL}#{path}")
end

def post_json(path, payload, token: nil)
  uri = build_uri(path)
  request = Net::HTTP::Post.new(uri)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{token}" if token
  request.body = JSON.dump(payload)
  perform_request(uri, request)
end

def get_json(path, token: nil)
  uri = build_uri(path)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{token}" if token
  perform_request(uri, request)
end

def perform_request(uri, request)
  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
    response = http.request(request)
    parsed = begin
      body_text = response.body.to_s
      body_text.empty? ? {} : JSON.parse(body_text)
    rescue JSON::ParserError
      { 'raw' => response.body }
    end
    { status: response.code.to_i, body: parsed }
  end
end

def admin_confirm(username)
  client = Aws::CognitoIdentityProvider::Client.new(region: AWS_REGION)
  client.admin_confirm_sign_up(user_pool_id: USER_POOL_ID, username: username)
  { status: 200, body: { 'message' => 'User confirmed via AdminConfirmSignUp' } }
rescue Aws::CognitoIdentityProvider::Errors::ServiceError => e
  { status: 400, body: { 'error' => e.message } }
end

def pretty_print_response(label, result)
  puts "\n#{label} (status #{result[:status]}):"
  puts JSON.pretty_generate(result[:body])
rescue JSON::GeneratorError
  puts result[:body]
end

suggested_username = "user_#{SecureRandom.hex(3)}"
suggested_email = "#{suggested_username}@example.com"
default_password = 'Password123!'

auth_payload = {
  username: ask('Username', suggested_username),
  password: ask('Password', default_password),
  email: ask('Email (use a reachable inbox if you want to confirm manually)', suggested_email),
  name: ask('Display name', 'Demo User')
}

puts "\nSigning up user..."
sign_up_result = post_json('/api/v1/auth/signup', { auth: auth_payload })
pretty_print_response('Signup response', sign_up_result)

if sign_up_result[:status] != 201
  puts '\nSignup failed, aborting.'
  exit 1
end

confirmation_choice = ask("Enter confirmation code, type 'admin' to confirm with admin privileges, or leave blank to skip", nil)

confirmation_result = nil
case confirmation_choice&.strip&.downcase
when nil, ''
  puts '\nSkipping confirmation step. Remember the user must be confirmed before sign-in succeeds.'
when 'admin'
  puts '\nConfirming user via AdminConfirmSignUp...'
  confirmation_result = admin_confirm(auth_payload[:username])
  pretty_print_response('Admin confirmation', confirmation_result)
else
  puts '\nConfirming user with provided code...'
  confirmation_result = post_json('/api/v1/auth/confirm', {
    auth: {
      username: auth_payload[:username],
      confirmation_code: confirmation_choice
    }
  })
  pretty_print_response('Confirmation response', confirmation_result)
end

puts '\nAttempting sign in...'
sign_in_result = post_json('/api/v1/auth/signin', {
  auth: {
    username: auth_payload[:username],
    password: auth_payload[:password]
  }
})
pretty_print_response('Signin response', sign_in_result)

unless sign_in_result[:status] == 200 && sign_in_result[:body]['access_token']
  puts '\nSignin failed. Make sure the user is confirmed and credentials are correct.'
  exit 1
end

access_token = sign_in_result[:body]['access_token']
id_token = sign_in_result[:body]['id_token']
token_for_api = id_token || access_token

puts "\nCalling protected endpoint /api/v1/posts using #{id_token ? 'ID token' : 'access token'}..."
posts_result = get_json('/api/v1/posts', token: token_for_api)
pretty_print_response('Posts response', posts_result)

puts "\nAll done. Tokens available: access_token=#{access_token ? 'yes' : 'no'}, id_token=#{id_token ? 'yes' : 'no'}"
