require 'lib/category'
require 'active_support'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/inflections'

module PageHelper
  def all_categories
    Category.all
  end

  def page_title
    cat = current_page.metadata[:locals][:cat]
    name_from_path = current_page.path.gsub('/index.html', '').gsub('.html', '').to_s.humanize
    name = cat.try(:title) || current_page.data.title.presence || name_from_path
    if current_page.data.skip_title
      name = nil
    end
    [name, "Rust Libraries"].compact.join(" &mdash; ")
  end
end
