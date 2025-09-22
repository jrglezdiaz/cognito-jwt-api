#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'json'
require 'net/http'
require 'uri'

API_BASE_URL = ENV.fetch('API_BASE_URL', 'http://localhost:3000').chomp('/').freeze

def ask(prompt, default = nil)
  print default ? "#{prompt} [#{default}]: " : "#{prompt}: "
  value = STDIN.gets&.strip
  value = nil if value&.empty?
  value || default
end

puts '\n== Protected endpoint tester ==\n'
endpoint_path = ask('Endpoint path', '/api/v1/posts')
http_method = ask('HTTP verb (GET/POST/PUT/PATCH/DELETE)', 'GET').to_s.upcase
bearer_default = ENV['COGNITO_TEST_TOKEN']
access_token = ask('Bearer token', bearer_default)

if access_token.to_s.empty?
  abort 'Bearer token requerido.'
end

full_url = "#{API_BASE_URL}#{endpoint_path}"
uri = URI.parse(full_url)

request_class = case http_method
when 'POST' then Net::HTTP::Post
when 'PUT' then Net::HTTP::Put
when 'PATCH' then Net::HTTP::Patch
when 'DELETE' then Net::HTTP::Delete
else Net::HTTP::Get
end

request = request_class.new(uri)
request['Authorization'] = "Bearer #{access_token}"
request['Content-Type'] = 'application/json'

if %w[POST PUT PATCH].include?(http_method)
  body_input = ask('JSON body (deja vacío para {})', '{}')
  request.body = body_input.empty? ? '{}' : body_input
end

response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
  http.request(request)
end

puts "\n#{http_method} #{full_url}" \
     "\nStatus: #{response.code}"

parsed = begin
  body = response.body.to_s
  body.empty? ? {} : JSON.parse(body)
rescue JSON::ParserError
  body
end

puts '\nRespuesta:'
puts parsed.is_a?(String) ? parsed : JSON.pretty_generate(parsed)
