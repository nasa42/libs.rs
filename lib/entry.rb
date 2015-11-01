require 'rest-client'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'lib/mash'
require 'lib/database'

class Entry
  CRATES_IO_API_ENDPOINT = "https://crates.io/api/v1"
  GITHUB_API_ENDPOINT = "https://api.github.com/"

  attr_reader :id

  def initialize category, id, payload
    @category = category
    @id = id
    @payload = Mash.new payload
  end

  def fetch_from_origin
    {
      crates_io: fetch_from_crates_io,
      github: fetch_from_github,
    }
  end

  def cache
    @cache ||= Database.load.read_cache(@category, self)
  end

  def crate_cache
    cache.crates_io!.crate!
  end

  def github_cache
    cache.github!
  end

  def name 
    @payload.name || crate_cache.name || @id
  end

  def description
    @payload.description || crate_cache.description
  end

  def crates_io_downloads
    crate_cache.downloads
  end

  def licence
    crate_cache.license
  end

  def version
    crate_cache.max_version
  end

  def github_full_name
    github_cache.full_name
  end

  def github_forks
    github_cache.forks
  end

  def github_stars
    github_cache.stargazers_count
  end

  def github_first_commit_at
    Time.parse(github_cache.created_at)
  end

  def github_last_commit_at
    Time.parse(github_cache.pushed_at)
  end

  def homepage_url
    crate_cache.homepage
  end

  def repository_url
    crate_cache.repository
  end

  def crate_url
    "https://crates.io/crates/#{crates_io_id}"
  end

  def crates_io_id
    id
  end

  def github_repo
    url = crate_cache.repository.presence || fetch_from_crates_io.crate!.repository
    return if url.blank?
    URI.parse(url).path =~ /\/([^\/]+\/[^\/]+)/
    $1
  end

  protected

  def fetch_from_crates_io
    @crates_io_response ||= -> do
      puts "Fetching crates.io/#{crates_io_id}"
      rest = RestClient::Resource.new(CRATES_IO_API_ENDPOINT)
      Mash.new JSON.parse(rest["crates/#{crates_io_id}"].get.body)
    end.call
  end

  def fetch_from_github
    puts "Fetching github.com/#{github_repo}"
    rest = RestClient::Resource.new(GITHUB_API_ENDPOINT)
    Mash.new JSON.parse(rest["repos/#{github_repo}"].get.body)
  end
end
