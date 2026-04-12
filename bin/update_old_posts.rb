#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'pathname'

POSTS_DIR = File.expand_path('../_posts', __dir__)

if !Dir.exist?(POSTS_DIR)
  abort("Error: _posts directory not found at #{POSTS_DIR}")
end

updated_files = []

Dir.glob(File.join(POSTS_DIR, '**', '*.md')).sort.each do |path|
  text = File.read(path)
  next unless text.start_with?("---\n")

  parts = text.split(/^---\s*$\n/)
  next if parts.size < 3

  raw_front_matter = parts[1]
  body = parts[2..-1].join("---\n")

  begin
    front_matter = YAML.safe_load(raw_front_matter, permitted_classes: [Date, Time]) || {}
  rescue Psych::SyntaxError => e
    warn "Skipping #{path}: YAML syntax error - #{e.message}"
    next
  end

  original_front_matter = front_matter.dup
  title = front_matter['title']
  background = front_matter['background']

  if title && (!front_matter.key?('description') || front_matter['description'].to_s.strip.empty?)
    front_matter['description'] = title.to_s.strip
  end

  if title && (!front_matter.key?('excerpt') || front_matter['excerpt'].to_s.strip.empty?)
    front_matter['excerpt'] = title.to_s.strip
  end

  if (!front_matter.key?('image') || front_matter['image'].to_s.strip.empty?) && background && !background.to_s.strip.empty?
    front_matter['image'] = background.to_s.strip
  end

  next if front_matter == original_front_matter

  ordered_keys = [
    'layout',
    'title',
    'subtitle',
    'date',
    'categories',
    'tags',
    'description',
    'excerpt',
    'background',
    'image'
  ]

  new_lines = ["---"]

  ordered_keys.each do |key|
    next unless front_matter.key?(key)

    value = front_matter[key]
    if value.is_a?(Array)
      serialized = value.inspect
    else
      serialized = value.to_s.include?(':') || value.to_s.match?(/['"\n]/) ? value.inspect : value.to_s
    end
    new_lines << "#{key}: #{serialized}"
  end

  remaining_keys = front_matter.keys - ordered_keys
  remaining_keys.each do |key|
    value = front_matter[key]
    serialized = value.is_a?(Array) ? value.inspect : value.to_s.include?(':') || value.to_s.match?(/['"\n]/) ? value.inspect : value.to_s
    new_lines << "#{key}: #{serialized}"
  end

  new_lines << "---"
  new_text = new_lines.join("\n") + "\n\n" + body
  File.write(path, new_text)
  updated_files << path
end

if updated_files.empty?
  puts 'No old posts needed updates.'
else
  puts "Updated #{updated_files.size} post(s):"
  updated_files.each { |path| puts "- #{Pathname.new(path).relative_path_from(Pathname.new(Dir.pwd))}" }
end
