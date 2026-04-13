module Jekyll
  Hooks.register :documents, :post_init do |doc, _|
    next unless doc.collection.label == "posts"
    next if doc.data.key?("permalink") && doc.data["permalink"]

    title = doc.data["title"] || File.basename(doc.basename_without_ext)
    slug = Utils.slugify(title, mode: "ascii", cased: false)

    categories = Array(doc.data["categories"] || doc.data["category"])
    if categories.empty?
      parts = File.dirname(doc.relative_path).split(File::SEPARATOR)
      categories = parts[1..-1] || []
    end
    categories = categories.map { |category| Utils.slugify(category.to_s, mode: "ascii", cased: false) }
    category_path = categories.compact.reject(&:empty?).join("/")

    if category_path.empty?
      doc.data["permalink"] = "/#{slug}/"
    else
      doc.data["permalink"] = "/#{category_path}/#{slug}/"
    end
  end
end
