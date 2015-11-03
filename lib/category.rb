require 'toml'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array/conversions.rb'
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

    def find_path id
      categories_path.join("#{id}.toml")
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

  def description_or_entries
    description.presence || entries.map(&:name).to_sentence
  end

  def related
    @toml.related.map do |id|
      self.class.new id, TOML.load_file(self.class.find_path(id))
    end
  end

  def entries
    @entires ||= @toml.entry!.map do |id, payload|
      Entry.new(self, id, payload)
    end
  end
end
