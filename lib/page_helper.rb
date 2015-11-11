require 'lib/category'
require 'active_support'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'

module PageHelper
  RUST_LOGO_PATH = "https://www.rust-lang.org/logos/rust-logo-blk.svg"
  CANONICAL_SITE = "http://libs.rs"
  
  def all_categories
    Category.all
  end

  def cat
    current_page.metadata[:locals][:cat]
  end

  def page_title
    name_from_path = current_page.path.gsub('/index.html', '').gsub('.html', '').to_s.humanize
    name = cat.try(:title) || current_page.data.title.presence || name_from_path
    if current_page.data.skip_title
      name = nil
    end
    [name, "Rust Libraries"].compact.join(" &mdash; ")
  end

  def canonical_url
    "#{CANONICAL_SITE}#{current_page.url}"
  end

  def fa_icon type
   "<i class=\"fa fa-#{type}\"></i>"
  end

  def formatted_time time
    return if time.blank?
    s = time.strftime("%-d %B %Y")
    "<time datetime=\"#{time.iso8601}\">#{s}</time>"
  end

  def meta_tags
    values = []
    values << { property: "og:title", content: page_title }
    values << { property: "og:type", content: "website" }
    values << { property: "og:url", content: canonical_url }
    values << { property: "og:image", content: RUST_LOGO_PATH }
    values << { property: "og:site_name", content: "Rust Libraries" }
    values << { property: "og:locale", content: "en-GB" }

    values << { itemprop: "name", content: page_title }
    values << { itemprop: "image", content: RUST_LOGO_PATH }

    desc = current_page.data.page_description.presence || cat.try(:description)
    if desc.present?
      values << { name: "description", content: desc }
      values << { property: "og:description", cotent: desc }
      values << { itemprop: "description", content: desc }
    end
    
    tags = ""
    values.each do |value|
      attributes = value.map do |k,v|
        "#{k}=\"#{v}\""
      end.join(" ")
      tags << "<meta #{attributes} />\n"
    end
    return tags
  end

end
