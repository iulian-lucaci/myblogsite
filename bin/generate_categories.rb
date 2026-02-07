#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'

# Read _config.yml
config_path = File.join(__dir__, '..', '_config.yml')
config = YAML.load_file(config_path)

# Extract categories from collections.posts.categories
categories = config.dig('collections', 'posts', 'categories') || []

if categories.empty?
  puts "No categories found in _config.yml"
  exit 0
end

puts "Generating category pages for: #{categories.join(', ')}"

# Create category pages
categories.each do |category|
  # Titleize the category name
  title = category.split(/[-_]/).map(&:capitalize).join(' ')
  
  # Create directory
  category_dir = File.join(__dir__, '..', 'categories', category)
  FileUtils.mkdir_p(category_dir)
  
  # Create index.md file
  index_path = File.join(category_dir, 'index.md')
  
  # Skip if file already exists
  if File.exist?(index_path)
    puts "  ✓ #{category}/index.md (already exists)"
    next
  end
  
  # Create front matter
  front_matter = <<~FRONT
    ---
    layout: category
    title: #{title}
    category: #{category}
    permalink: /categories/#{category}/
    ---
  FRONT
  
  File.write(index_path, front_matter.strip + "\n")
  puts "  ✓ Created #{category}/index.md"
end

puts "Done! Category pages generated in /categories/"
