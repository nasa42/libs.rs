require 'toml'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/array/conversions'
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
          new path.sub(/\.toml$/, '')
        end
      end
    end

    def find_path id
      categories_path.join("#{id}.toml")
    end
  end

  def initialize id, toml = nil
    @id = id
    if toml.nil?
      @toml = Mash.new TOML.load_file(self.class.find_path(@id))
    else
      @toml = Mash.new toml
    end
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
      self.class.new id
    end
  end

  def unsorted_entries
    @unsorted_entires ||= @toml.entry!.map do |id, payload|
      Entry.new(self, id, payload)
    end
  end

  def entries
    @entries ||= unsorted_entries.sort_by do |entry|
      entry.weight(max_stars, max_forks, max_downloads)
    end.reverse
  end

  def find_entry entry_id
    unsorted_entries.detect { |e| e.id.to_s == entry_id.to_s }
  end

  def max_stars
    unsorted_entries.map(&:weight_stars).max
  end

  def max_forks
    unsorted_entries.map(&:weight_forks).max
  end

  def max_downloads
    unsorted_entries.map(&:crates_io_downloads).max
  end
end
