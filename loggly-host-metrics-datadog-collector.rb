#!/usr/bin/env ruby

require 'datadog/statsd'
require 'httparty'
require 'json'

LOGGLY_API_TOKEN = ENV['LOGGLY_API_TOKEN']

loggly_url = "https://recfive.loggly.com/apiv2/fields/syslog.host?from=-5m"
loggly_headers = { "Authorization" => "Bearer #{LOGGLY_API_TOKEN}" }

resp = HTTParty.get(loggly_url, headers: loggly_headers)

if resp.success?
  message_counts = JSON.parse(resp.body)

  statsd_addr = ENV['STATSD_ADDR'].split(":")
  statsd = Datadog::Statsd.new(statsd_addr[0], statsd_addr[1].to_i)

  message_counts['syslog.host'].each do |metric|
    count = metric['count']
    instance_id = metric['term']

    statsd.gauge('loggly.log_message_count', count, tags: ["instance_id:#{instace_id}"])
  end
else
  puts "Failed to retrieve message counts from Loggly. (response code: #{resp.code}, response body: #{resp.body})"
end
