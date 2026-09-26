# Adds responsive srcset, lazy loading, async decoding, and lightbox anchors to local markdown images.
# It only processes markdown-generated pages/posts to avoid rewriting inline JS strings.

require 'cgi'
require 'nokogiri'

module Jekyll
  module ResponsiveImageSrcset
    def self.process_html(html, page)
      return html unless html

      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      add_lightbox_anchors(doc, page)

      doc.css('img').to_a.each do |img|
        src = img['src']
        next unless src
        next if src =~ %r{\A(?:https?:|data:)}i

        img['loading'] = 'lazy' unless img['loading']
        img['decoding'] = 'async' unless img['decoding']

        src_path = src.sub(%r{\A/}, '')
        source_path = File.join(page.site.source, src_path)
        variant_path = find_variant(source_path)

        next unless variant_path

        srcset = build_srcset(src, source_path, variant_path)
        next unless srcset

        img['srcset'] = srcset
        img['sizes'] = '(max-width: 768px) 100vw, 768px'
      end

      doc.to_html
    end

    def self.add_lightbox_anchors(doc, page)
      gallery_id = "glightbox-#{page.url.gsub(/[^a-z0-9]+/i, '-') }"

      doc.css('img').to_a.each do |img|
        next if img.ancestors('a').any?

        src = img['src']
        next unless src
        next if src =~ %r{\A(?:https?:|data:)}i

        alt_value = img['alt'].to_s
        title_attr = escape_html(alt_value)

        unless alt_value.include?('@transylvaniadigitalantiques.com')
          alt_value = alt_value + ' © transylvaniadigitalantiques.com'
          img['alt'] = alt_value
          title_attr = escape_html(alt_value)
        end

        anchor = Nokogiri::XML::Node.new('a', doc)
        anchor['href'] = src
        anchor['class'] = 'glightbox'
        anchor['data-gallery'] = gallery_id
        anchor['data-title'] = title_attr unless title_attr.empty?
        img.add_previous_sibling(anchor)
        anchor.add_child(img)
      end
    end

    def self.find_variant(source_path)
      return nil unless File.exist?(source_path)

      dirname = File.dirname(source_path)
      basename = File.basename(source_path, '.*')
      ext = File.extname(source_path)

      if basename =~ /^(.*) - ([12])$/
        base = Regexp.last_match(1)
        part = Regexp.last_match(2)
        other_suffix = part == '1' ? '2' : '1'
        candidate = File.join(dirname, "#{base} - #{other_suffix}#{ext}")
        return candidate if File.exist?(candidate)
      end

      nil
    end

    def self.build_srcset(src, source_path, variant_path)
      sizes = variant_sizes(source_path, variant_path)
      return nil unless sizes

      variant_url = if src.end_with?(" - 1#{File.extname(src)}")
                      src.sub(/ - 1(\.[^.]+)\z/, ' - 2\1')
                    elsif src.end_with?(" - 2#{File.extname(src)}")
                      src.sub(/ - 2(\.[^.]+)\z/, ' - 1\1')
                    else
                      nil
                    end
      return nil unless variant_url

      if sizes[:small] == source_path
        "#{src} 1x, #{variant_url} 2x"
      else
        "#{variant_url} 1x, #{src} 2x"
      end
    end

    def self.variant_sizes(src_path, variant_path)
      src_size = File.size(src_path) rescue nil
      variant_size = File.size(variant_path) rescue nil
      return nil unless src_size && variant_size

      if src_size <= variant_size
        { small: src_path, large: variant_path }
      else
        { small: variant_path, large: src_path }
      end
    end

    def self.escape_html(value)
      CGI.escapeHTML(value.to_s)
    end
  end
end

Jekyll::Hooks.register [:documents], :post_render do |page|
  next unless ['.md', '.markdown'].include?(page.extname)
  page.output = Jekyll::ResponsiveImageSrcset.process_html(page.output, page)
end
