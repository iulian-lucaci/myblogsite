#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'pathname'

POSTS_DIR = File.expand_path('../_posts', __dir__)

def clean_text(text)
  result = text.dup
  result.gsub!(/<script.*?>.*?<\/script>/m, ' ')
  result.gsub!(/<style.*?>.*?<\/style>/m, ' ')
  result.gsub!(/<[^>]+>/, ' ')
  result.gsub!(/!\[[^\]]*\]\([^\)]*\)/, ' ')
  result.gsub!(/\[([^\]]+)\]\([^\)]*\)/, '\1')
  result.gsub!(/[`*_]{1,3}([^`*_]+)[`*_]{1,3}/, '\1')
  result.gsub!(/#+\s*/, ' ')
  result.gsub!(/\s*\n\s*/, ' ')
  result.gsub!(/\s+/, ' ')
  result.strip
end

def extract_section(body, section_name)
  marker = /^\s*#+\s*#{Regexp.escape(section_name)}\b.*$/i
  return nil unless body =~ marker

  section_text = body.split(marker, 2)[1]
  section_text = section_text.split(/^\s*#+\s*.*$/)[0]
  cleaned = clean_text(section_text).strip
  cleaned.empty? ? nil : cleaned
end

def first_paragraph(body, title = nil)
  if section = extract_section(body, 'Description')
    return section if title.nil? || section.strip != title.strip
  end

  candidates = body.split(/\r?\n{2,}/).map(&:strip)
  candidates.each do |para|
    next if para.empty?
    next if para =~ /^\s*!\[|<img/i

    para = para.gsub(/^\s*#+.*$/, '')
    para = para.gsub(/^\s*####.*$/, '')
    para = para.gsub(/^\s*\*\s+/, '')
    para = para.gsub(/^\s*[-+]\s+/, '')
    para = clean_text(para).strip

    next if para.empty?
    next if title && para.strip == title.strip
    next if para.length < 50
    return para
  end
  nil
end

def truncate_text(text, limit)
  return text if text.length <= limit
  truncated = text[0, limit].sub(/\s+\S+\s*$/, '')
  truncated.strip + '...'
end

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
  title = front_matter['title']&.to_s&.strip
  background = front_matter['background']&.to_s&.strip
  description = front_matter['description']&.to_s&.strip
  excerpt = front_matter['excerpt']&.to_s&.strip

  body_paragraph = first_paragraph(body, title)

  if title && (description.nil? || description.empty? || description == title)
    if body_paragraph && !body_paragraph.empty?
      front_matter['description'] = truncate_text(body_paragraph, 160)
    else
      front_matter['description'] = title
    end
  end

  if title && (excerpt.nil? || excerpt.empty? || excerpt == title)
    if body_paragraph && !body_paragraph.empty?
      front_matter['excerpt'] = truncate_text(body_paragraph, 120)
    else
      front_matter['excerpt'] = title
    end
  end

  if (!front_matter.key?('image') || front_matter['image'].to_s.strip.empty?) && background && !background.empty?
    front_matter['image'] = background
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
