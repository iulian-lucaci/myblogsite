module Jekyll
  class FullSitemapGenerator
    def self.format_time(time)
      time.utc.strftime('%Y-%m-%dT%H:%M:%S+00:00')
    end

    def self.build_sitemap(site)
      url_root = site.config['url'].to_s.chomp('/')
      sitemap_path = File.join(site.dest, 'sitemap.xml')

      html_files = Dir[File.join(site.dest, '**', '*.html')].sort
      urls = html_files.map do |filepath|
        rel = filepath.sub(%r{\A#{Regexp.escape(site.dest)}}, '')
        next if rel == '/sitemap.xml'
        next if rel == '/404.html' || rel == '/410.html'

        rel = rel.sub(%r{/index\.html\z}, '/')
        rel = '/' if rel == ''
        rel
      end.compact.uniq

      File.open(sitemap_path, 'w') do |f|
        f.puts '<?xml version="1.0" encoding="UTF-8"?>'
        f.puts '<urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'

        urls.each do |page_url|
          file_path = File.join(site.dest, page_url.sub(%r{\A/}, ''))
          file_path = File.join(file_path, 'index.html') if page_url.end_with?('/')
          lastmod = File.mtime(file_path) rescue nil

          f.puts '  <url>'
          f.puts "    <loc>#{url_root}#{page_url}</loc>"
          f.puts "    <lastmod>#{format_time(lastmod)}</lastmod>" if lastmod
          f.puts '  </url>'
        end

        f.puts '</urlset>'
      end
    end
  end

  Hooks.register :site, :post_write do |site|
    FullSitemapGenerator.build_sitemap(site)
  end
end
