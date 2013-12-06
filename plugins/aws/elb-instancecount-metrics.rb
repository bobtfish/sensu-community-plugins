#!/usr/bin/env ruby
#
# Fetch ELB instance count metrics for each ELB in a region
# ===
#
# Copyright 2013 Tomas Doran 
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.
#
# Gets instance count metrics from the ELB and puts them in Graphite for longer term storage
#
# Needs fog gem
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'fog'

class ELBMetrics < Sensu::Plugin::Metric::CLI::Graphite

  option :scheme,
    :description => "Metric naming scheme, text to prepend to metric",
    :short => "-s SCHEME",
    :long => "--scheme SCHEME",
    :default => ""

  option :aws_access_key,
    :short => '-a AWS_ACCESS_KEY',
    :long => '--aws-access-key AWS_ACCESS_KEY',
    :description => "AWS Access Key. Either set ENV['AWS_ACCESS_KEY_ID'] or provide it as an option",
    :required => true

  option :aws_secret_access_key,
    :short => '-k AWS_SECRET_ACCESS_KEY',
    :long => '--aws-secret-access-key AWS_SECRET_ACCESS_KEY',
    :description => "AWS Secret Access Key. Either set ENV['AWS_SECRET_ACCESS_KEY'] or provide it as an option",
    :required => true

  option :aws_region,
    :short => '-r AWS_REGION',
    :long => '--aws-region REGION',
    :description => "AWS Region (such as eu-west-1).",
    :default => 'us-east-1'

  def run
    if config[:scheme] == ""
      graphitepath = "#{config[:aws_region]}.elb_instancecount"
    else
      graphitepath = config[:scheme]
    end
    begin

      elb = Fog::AWS::ELB.new(
        :aws_access_key_id      => config[:aws_access_key],
        :aws_secret_access_key  => config[:aws_secret_access_key],
        :region                 => config[:aws_region])
      )

      data = {}
      elb.describe_load_balancers.body['DescribeLoadBalancersResult']['LoadBalancerDescriptions'].each do |lb|
        data[lb['LoadBalancerName']] = lb['Instances'].count
      end
      now = Time.now.to_i
      if data.keys.count > 0
        # We only return data when we have some to return
        data.keys.each do |elb_name|
          output "#{graphitepath}#{elb_name}", data[elb_name], now
        end
      end
    rescue Exception => e
      puts "Error: exception: #{e}"
      critical
    end
    ok
  end
end

