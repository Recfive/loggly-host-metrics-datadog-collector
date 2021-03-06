#!/usr/bin/env ruby

require 'aws-sdk-ecs'
require 'datadog/statsd'
require 'httparty'
require 'json'

LOGGLY_ACCOUNT_NAME = ENV.fetch('LOGGLY_ACCOUNT_NAME', 'recfive')
LOGGLY_API_TOKEN = ENV['LOGGLY_API_TOKEN']
STATSD_ADDR = ENV.fetch('STATSD_ADDR', 'localhost:8125')

ecs = Aws::ECS::Client.new

cluster_arns = [
  "arn:aws:ecs:us-east-1:925377207665:cluster/ecs-twofishes-201511091730-EcsCluster-YR3A5S85797V",
  "arn:aws:ecs:us-east-1:925377207665:cluster/ecs-201511091730-EcsCluster-RBGRNCYWHYV1"
]

container_instance_ids = []

cluster_arns.each do |cluster_arn|
  container_instance_arns = ecs.list_container_instances(cluster: cluster_arn).container_instance_arns
  container_instances = ecs.describe_container_instances(cluster: cluster_arn, container_instances: container_instance_arns).container_instances

  # We're only concerned with instances that have at least one running task on them
  container_instance_ids += container_instances.select {|ci| ci.running_tasks_count > 0 }.map {|ci| ci.ec2_instance_id }
end

loggly_url = "https://#{LOGGLY_ACCOUNT_NAME}.loggly.com/apiv2/fields/syslog.host?from=-1m"
loggly_headers = { "Authorization" => "Bearer #{LOGGLY_API_TOKEN}" }

resp = HTTParty.get(loggly_url, headers: loggly_headers)

if resp.success?
  message_counts = Hash[resp['syslog.host'].map {|e| [e['term'], e['count']] }]

  statsd_addr = STATSD_ADDR.split(":")
  statsd = Datadog::Statsd.new(statsd_addr[0], statsd_addr[1].to_i)

  container_instance_ids.each do |instance_id|
    if message_counts.key?(instance_id)
      count = message_counts[instance_id]
    else
      count = 0
    end

    statsd.increment('loggly.message_total', by: count, tags: ["instance_id:#{instance_id}"])
  end
else
  puts "Failed to retrieve message counts from Loggly. (response code: #{resp.code}, response body: #{resp.body})"
end
