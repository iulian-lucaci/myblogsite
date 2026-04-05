# Adds responsive srcset, lazy loading, async decoding, and lightbox anchors to local markdown images.
# It only processes markdown-generated pages/posts to avoid rewriting inline JS strings.

require 'cgi'

module Jekyll
  module ResponsiveImageSrcset
    IMAGE_TAG_PATTERN = /<img\b([^>]*?)>/i

    def self.process_html(html, page)
      return html unless html

      html = add_lightbox_anchors(html, page)

      html.gsub(IMAGE_TAG_PATTERN) do |img_tag|
        src_match = img_tag.match(/src=(['"])([^'">]+?)\1/i)
        src = src_match && src_match[2]
        next img_tag unless src
        next img_tag if src =~ %r{\A(?:https?:|data:)}i

        img_tag = add_loading_lazy(img_tag)
        img_tag = add_decoding_async(img_tag)

        src_path = src.sub(%r{\A/}, '')
        source_path = File.join(page.site.source, src_path)
        variant_path = find_variant(source_path)

        if variant_path
          srcset = build_srcset(src, source_path, variant_path)
          img_tag = img_tag.sub(/(\s*\/?>)\z/, " srcset=\"#{srcset}\" sizes=\"(max-width: 768px) 100vw, 768px\"\1") if srcset
        end

        img_tag
      end
    end

    def self.add_lightbox_anchors(html, page)
      gallery_id = "glightbox-#{page.url.gsub(/[^a-z0-9]+/i, '-') }"

      html.gsub(IMAGE_TAG_PATTERN) do |img_tag|
        position = Regexp.last_match.begin(0)
        before = html[0...position]

        if before.rindex('</a>') && before.rindex('<a') && before.rindex('<a') > before.rindex('</a>')
          next img_tag
        end

        src_match = img_tag.match(/src=(['"])([^'">]+?)\1/i)
        next img_tag unless src_match
        src = src_match[2]
        next img_tag if src =~ %r{\A(?:https?:|data:)}i

        alt_match = img_tag.match(/alt=(['"])([^'">]*?)\1/i)
        title_attr = alt_match ? escape_html(alt_match[2]) : nil

        # Add copyright to alt text if not already present
        if alt_match
          alt_value = alt_match[2]
          unless alt_value.include?('@transylvaniadigitalantiques.com')
            alt_value += ' © transylvaniadigitalantiques.com'
            img_tag = img_tag.sub(/alt=(['"])([^'">]*?)\1/i, "alt=\"#{escape_html(alt_value)}\"")
            title_attr = escape_html(alt_value)
          end
        else
          # Add alt attribute with copyright if missing
          img_tag = img_tag.sub(/(\s*\/?>)\z/, " alt=\"© transylvaniadigitalantiques.com\"\1")
          title_attr = '© transylvaniadigitalantiques.com'
        end

        link_attrs = ["href=\"#{src}\"", 'class="glightbox"', "data-gallery=\"#{gallery_id}\""]
        link_attrs << "data-title=\"#{title_attr}\"" if title_attr

        "<a #{link_attrs.join(' ')}>#{img_tag}</a>"
      end
    end

    def self.add_loading_lazy(img_tag)
      add_attribute(img_tag, 'loading', 'lazy')
    end

    def self.add_decoding_async(img_tag)
      add_attribute(img_tag, 'decoding', 'async')
    end

    def self.add_attribute(img_tag, name, value)
      return img_tag if img_tag =~ /\b#{Regexp.escape(name)}=/i
      img_tag.sub(/(\s*\/?>)\z/, " #{name}=\"#{value}\"\1")
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
