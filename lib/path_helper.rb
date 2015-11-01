module PathHelper
  ROOT = File.expand_path("..", File.dirname(__FILE__))
  
  def root_path
    Pathname.new ROOT
  end

  def lib_path
    root_path.join("lib")
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
end
