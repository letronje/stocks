#!/usr/bin/env ruby

require "json"
require "optionparser"

require "rubygems"
require "bundler/setup"
Bundler.require(:default)

require "active_support/all"

require_relative "marketstack"

options = {}
OptionParser.new do |opts|
  opts.on("-ak", "--apikey API_KEY", "MarketStack API Key") do |v|
    options[:apikey] = v
  end
end.parse!

key = options[:apikey]
if key.blank?
  puts "MarketStack API Key arg is missing"
  exit
end

MarketStack.write_to_disk_cache!(key, "cache.json")
