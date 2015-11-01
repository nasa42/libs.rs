require 'json'
require 'active_support'
require 'active_support/core_ext/date/calculations'
require 'active_support/core_ext/time/calculations'
require 'lib/path_helper'
require 'lib/mash'
require 'lib/category'
require 'lib/entry'

class Database
  VERSION = 1
  
  include PathHelper

  attr_reader :db

  class << self
    def load
      @@instance ||= new
    end
  end

  def initialize
    unless File.exist? db_path
      init_db
    else
      @db = Mash.new JSON.load db_path
    end
    ensure_current_version!
  end

  def save
    File.write(db_path, @db.to_json)
  end

  def init_db
    FileUtils.mkdir_p File.dirname(db_path)
    @db = Mash.new(version: VERSION)
  end

  def ensure_current_version!
    VERSION == @db.version || init_db
  end

  def prepare
    Category.all.each do |cat|
      cat.entries.each do |entry|
        if cache_expired?(cat, entry)
          write_cache(cat, entry, entry.fetch_from_origin)
        end
      end
    end
    return self
  end

  def read_cache cat, entry
    @db.cache!.fetch!(cat.id).fetch!(entry.id)
  end

  def write_cache cat, entry, payload
    @db.cache!.fetch!(cat.id)[entry.id] = payload.merge(fetch_timestamp: Time.now.tv_sec)
  end

  def cache_expired? cat, entry
    read_cache(cat, entry).fetch_timestamp.to_i < Time.now.yesterday.tv_sec
  end
end
