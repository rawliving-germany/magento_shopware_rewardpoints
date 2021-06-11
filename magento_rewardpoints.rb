#!/usr/bin/env ruby

# SPDX-FileCopyrightText: 2021 Felix Wolfsteller
#
# SPDX-License-Identifier: AGPL-3.0-or-later

require 'optparse'
require 'mysql2'
require 'tty-prompt'
require 'json'

options = {}

option_parser = OptionParser.new do |parser|
  parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
  parser.separator "Read reward points from magento database and dumps them as json"
  parser.on('-u', '--username DBUSERNAME', 'username for (magento) database authentication')
  parser.on('-p', '--password DBPASSWORD', 'password for (magento) database authentication')
  parser.on('-d', '--databasename DBNAME', 'name of (magento) database')
  parser.on('--pretty', 'pretty print the json')
  parser.on_tail("-h", "--help", "Show this message and exit") do
    puts parser
    exit
  end
end

option_parser.parse!(into: options)

if options[:databasename].to_s.strip == ''
  puts option_parser

  exit 1
end

prompt = TTY::Prompt.new
error_prompt = TTY::Prompt.new(output: STDERR)

begin
  mysql_client = Mysql2::Client.new host: '127.0.0.1',
    username: options[:username],
    password: options[:password],
    database: options[:databasename]
rescue Mysql2::Error::ConnectionError => e
  error_prompt.error e
  puts "Maybe you want to pass mysql connection parameters:"
  puts option_parser
  exit 2
end

query = <<~SQL
  SELECT customer_id, SUM(amount) as amount FROM mst_rewards_transaction GROUP BY customer_id
SQL

# id -> points
customer_reward_points = mysql_client.query(
  query, symbolize_keys: true)
  .map { |row| [row[:customer_id], row[:amount]] }.to_h

query = <<~SQL
  SELECT entity_id, email from customer_entity;
SQL

# id -> email
customer_emails = mysql_client.query(
  query, symbolize_keys: true)
  .map { |row| [row[:entity_id], row[:email]] }.to_h

points_by_mail = {}

# email -> points
customer_reward_points.each do |id, points|
  points_by_mail[customer_emails[id]] = points
end

if options[:pretty]
  puts JSON.pretty_generate points_by_mail
else
  puts points_by_mail.to_json
end

# Exit with grace
exit 0
