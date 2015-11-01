require 'toml'
require 'lib/path_helper'
require 'lib/mash'
require 'lib/entry'

class Category

  attr_reader :id
  
  class << self
    include PathHelper
    
    def all
      Dir.chdir(categories_path) do
        return Dir["*.toml"].map do |path|
          new path.sub(/\.toml$/, ''), TOML.load_file(path)
        end
      end
    end
  end

  def initialize id, toml
    @id = id
    @toml = Mash.new toml
  end

  def title
    @toml.title
  end

  def description
    @toml.description
  end

  def related
    @toml.related
  end

  def entries
    @toml.entry!.map do |id, payload|
      Entry.new(self, id, payload)
    end
  end
end
