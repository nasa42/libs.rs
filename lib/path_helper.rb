module PathHelper
  ROOT = File.expand_path("..", File.dirname(__FILE__))
  
  def root_path
    Pathname.new ROOT
  end

  def lib_path
    root_path.join("lib")
  end

  def build_path
    root_path.join("build")
  end

  def tmp_path
    root_path.join("tmp")
  end

  def db_path
    tmp_path.join("database.json")
  end

  def categories_path
    root_path.join("categories")
  end

  # WARNING: This path will be cleaned on every deploy!
  def gh_pages_repo_path
    tmp_path.join("gh-pages-repo")
  end
end
