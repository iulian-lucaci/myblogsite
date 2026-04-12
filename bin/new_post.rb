#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'time'

options = {
  category: nil,
  categories: [],
  tags: [],
  subtitle: nil,
  background: nil,
  image: nil,
  description: nil,
  excerpt: nil,
  publish_date: Time.now,
  force: false,
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby bin/new_post.rb [options] \"Post Title\""

  opts.on('-c', '--category CATEGORY', 'Primary post category (required)') do |value|
    options[:category] = value.strip
  end

  opts.on('--categories x,y,z', Array, 'Comma-separated categories list') do |list|
    options[:categories] = list.map(&:strip).reject(&:empty?)
  end

  opts.on('-t', '--tags x,y,z', Array, 'Comma-separated tags list') do |list|
    options[:tags] = list.map(&:strip).reject(&:empty?)
  end

  opts.on('-s', '--subtitle TEXT', 'Optional subtitle for the post') do |value|
    options[:subtitle] = value.strip
  end

  opts.on('-b', '--background PATH', 'Optional background image path for the post') do |value|
    options[:background] = value.strip
  end

  opts.on('-i', '--image PATH', 'Optional social image path for the post') do |value|
    options[:image] = value.strip
  end

  opts.on('-d', '--description TEXT', 'Meta description for SEO') do |value|
    options[:description] = value.strip
  end

  opts.on('-e', '--excerpt TEXT', 'Short excerpt for the post') do |value|
    options[:excerpt] = value.strip
  end

  opts.on('--date DATE', 'Publish date in YYYY-MM-DD or YYYY-MM-DD HH:MM:SS format') do |value|
    options[:publish_date] = Time.parse(value)
  rescue ArgumentError
    abort("Invalid date format: #{value}")
  end

  opts.on('-f', '--force', 'Overwrite existing file if it already exists') do
    options[:force] = true
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end

parser.parse!

title = ARGV.join(' ').strip

if title.empty?
  abort("Error: A title is required. Usage: ruby bin/new_post.rb -c transylvania \"Post Title\"")
end

if options[:category].nil? && options[:categories].empty?
  abort("Error: At least one category is required. Use --category or --categories.")
end

categories = options[:categories]
categories.unshift(options[:category]) if options[:category]
categories.map!(&:strip)
categories.reject!(&:empty?)

primary_category = categories.first
slug = title.downcase.strip.gsub(/[^a-z0-9]+/, '-').gsub(/(^-|-$)/, '')
filename = "#{options[:publish_date].strftime('%Y-%m-%d')}-#{slug}.md"
folder = File.join('_posts', primary_category)
FileUtils.mkdir_p(folder)
filepath = File.join(folder, filename)

if File.exist?(filepath) && !options[:force]
  abort("Error: #{filepath} already exists. Use --force to overwrite.")
end

front_matter = [
  '---',
  'layout: post',
  "title: \"#{title.gsub('"', '\\"')}\"",
]

front_matter << "subtitle: \"#{options[:subtitle].gsub('"', '\\"')}\"" if options[:subtitle]
front_matter << "date: #{options[:publish_date].strftime('%Y-%m-%d %H:%M:%S')}"
front_matter << "categories: [#{categories.map { |c| c.strip }.map { |c| c.include?(',') ? "\"#{c}\"" : c }.join(', ')}]"
front_matter << "tags: [#{options[:tags].map { |tag| tag.strip }.map { |tag| tag.include?(',') ? "\"#{tag}\"" : tag }.join(', ')}]" unless options[:tags].empty?
front_matter << "description: \"#{options[:description].gsub('"', '\\"')}\"" if options[:description]
front_matter << "excerpt: \"#{options[:excerpt].gsub('"', '\\"')}\"" if options[:excerpt]
front_matter << "background: '#{options[:background]}'" if options[:background]
front_matter << "image: '#{options[:image]}'" if options[:image]
front_matter << '---'
front_matter << ''
front_matter << 'Write your content here.'

File.write(filepath, front_matter.join("\n"))

puts "Created new post: #{filepath}"
