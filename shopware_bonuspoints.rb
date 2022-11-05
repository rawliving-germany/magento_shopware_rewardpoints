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
  parser.banner = "Usage: #{$PROGRAM_NAME} [options] [input.json]"
  parser.separator "Read bonus points def from stdin or json file and import them in a shopware db"
  parser.on('-u', '--username DBUSERNAME', 'username for (shopware) database authentication')
  parser.on('-p', '--password DBPASSWORD', 'password for (shopware) database authentication')
  parser.on('-d', '--databasename DBNAME', 'name of (shopware) database')
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

# We want all
# "./outme | PROGRAM",
# "PROGRAM < file"
# and ""PROGRAM file" to work

if ARGF.filename != "-" or (not STDIN.tty? and not STDIN.closed?)
  json_content = JSON.parse(ARGF.read, symbolize_names: true)
else
  error_prompt.error "input missing (file argument, or pipe data via stdin)"
  puts option_parser

  exit 1
end

json_content = JSON.parse(ARGF.read)
mail_to_points = json_content

# Forget about those without points
mail_to_points.delete_if {|m,p| p.to_i == 0}

sql_mail_in = mail_to_points.keys.
  map{|m| "\"#{m}\"" }.
  join(",")

query = <<~SQL
  SELECT email, id FROM s_user WHERE email IN (#{sql_mail_in})
SQL

mail_user_id = mysql_client.query(query, symbolize_keys: true)
  .map { |row| [row[:email], row[:id]] }.to_h

mail_user_id.each do |mail,id|
  query = <<~SQL
    SELECT points FROM s_core_plugins_bonus_user_points WHERE userID = #{id}
  SQL

  points = (mail_to_points[mail.to_sym].to_i / 2.0).ceil

  # Update points if possible (already)
  if mysql_client.query(query).count == 1
    query = <<~SQL
      UPDATE s_core_plugins_bonus_user_points
        SET points = #{ points }
        WHERE userID = #{id}
    SQL
    # /* email: #{mail} */
  else
    query = <<~SQL
      INSERT INTO s_core_plugins_bonus_user_points (userID, points) VALUES (#{id}, #{ points })
    SQL
      #/* email: #{mail} */
  end

  mysql_client.query(query)

  query = <<~SQL
    INSERT INTO s_core_plugins_bonus_user_points_reasons
      (userID, difference, type, context, time) VALUES
      (#{id},  #{ points }, 'admin', "Übernahme aus altem Shop", curdate())
  SQL
      #/* email: #{mail} */

  mysql_client.query(query)
end

# Exit gracefully
exit 0
