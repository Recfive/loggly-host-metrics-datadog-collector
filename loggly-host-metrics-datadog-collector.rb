#!/usr/bin/env ruby

require 'datadog/statsd'
require 'httparty'
require 'json'

LOGGLY_ACCOUNT_NAME = ENV.fetch('LOGGLY_ACCOUNT_NAME', 'recfive')
LOGGLY_API_TOKEN = ENV['LOGGLY_API_TOKEN']
STATSD_ADDR = ENV.fetch('STATSD_ADDR', 'localhost:8125')

loggly_url = "https://#{LOGGLY_ACCOUNT_NAME}.loggly.com/apiv2/fields/syslog.host?from=-1m"
loggly_headers = { "Authorization" => "Bearer #{LOGGLY_API_TOKEN}" }

resp = HTTParty.get(loggly_url, headers: loggly_headers)

if resp.success?
  message_counts = JSON.parse(resp.body)

  statsd_addr = STATSD_ADDR.split(":")
  statsd = Datadog::Statsd.new(statsd_addr[0], statsd_addr[1].to_i)

  message_counts['syslog.host'].each do |metric|
    count = metric['count']
    instance_id = metric['term']

    statsd.increment('loggly.message_total', by: count, tags: ["instance_id:#{instance_id}"])
  end
else
  puts "Failed to retrieve message counts from Loggly. (response code: #{resp.code}, response body: #{resp.body})"
end
