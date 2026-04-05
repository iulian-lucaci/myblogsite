# Adds responsive srcset attributes to local markdown images when paired variants exist.
# It only processes markdown-generated pages/posts to avoid rewriting inline JS strings.

module Jekyll
  module ResponsiveImageSrcset
    IMAGE_TAG_PATTERN = /<img\b([^>]*?)\bsrc=(['"])([^'">]+?)\2([^>]*?)>/i

    def self.process_html(html, page)
      return html unless html

      html.gsub(IMAGE_TAG_PATTERN) do |img_tag|
        next img_tag if img_tag =~ /\bsrcset=/i

        src_match = img_tag.match(/src=(['"])([^'">]+?)\1/i)
        src = src_match && src_match[2]
        next img_tag unless src
        next img_tag if src =~ %r{\A(?:https?:|data:)}i

        src_path = src.sub(%r{\A/}, '')
        source_path = File.join(page.site.source, src_path)
        variant_path = find_variant(source_path)
        next img_tag unless variant_path

        srcset = build_srcset(src, source_path, variant_path)
        next img_tag unless srcset

        img_tag.sub(/>\z/, " srcset=\"#{srcset}\" sizes=\"(max-width: 768px) 100vw, 768px\">")
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

      variant_url = src.sub(/( - [12])(\.[^.]+)\z/, '\1\2')
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
  end
end

Jekyll::Hooks.register [:documents], :post_render do |page|
  next unless ['.md', '.markdown'].include?(page.extname)
  page.output = Jekyll::ResponsiveImageSrcset.process_html(page.output, page)
end
