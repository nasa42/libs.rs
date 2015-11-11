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

  def id_with_cat
    "#{@category.id}:#{id}"
  end

  def fetch_from_origin
    h = Mash.new
    crates_io_payload = fetch_from_crates_io
    github_payload = fetch_from_github
    h.crates_io = crates_io_payload if crates_io_payload.crate!.present?
    h.github = github_payload if github_payload.present?
    return h
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
    @payload.name || crate_cache.name.to_s.titlecase.presence || @id
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
    return if github_cache.created_at.blank?
    Time.parse(github_cache.created_at)
  end

  def github_last_commit_at
    return if github_cache.pushed_at.blank?
    Time.parse(github_cache.pushed_at)
  end

  def homepage_url
    @payload.homepage_url.presence || crate_cache.homepage.presence || repository_url || crate_url
  end

  def repository_url
    @payload.repository_url || crate_cache.repository
  end

  def has_github?
    repository_url =~ /github\.com/
  end

  def crate_url
    "https://crates.io/crates/#{crates_io_id}"
  end

  def crates_io_id
    if @payload.key?(:crates_io_id) && false == @payload.crates_io_id
      return false
    end
    @payload.crates_io_id.presence || id
  end

  def github_repo(fetch_live = false)
    @github_repo ||= -> do
      url = repository_url
      if url.blank? && fetch_live
        payload = fetch_from_crates_io
        payload && (url = payload.crate!.repository)
      end
      return if url.blank?
      URI.parse(url).path =~ /\/([^\/]+\/[^\/]+)/
      $1 && $1.sub(/\.git$/, '')
    end.call
  end

  protected

  def fetch_from_crates_io
    @crates_io_response ||= -> do
      if crates_io_id.blank?
        puts "crates.io is blank for #{id_with_cat}"
        return Mash.new
      end
      puts "Fetching crates.io/#{crates_io_id}"
      begin
        rest = RestClient::Resource.new(CRATES_IO_API_ENDPOINT)
        return Mash.new JSON.parse(rest["crates/#{crates_io_id}"].get.body)
      rescue RestClient::ResourceNotFound => e
        puts "[ERROR] #{e.class} - #{e.message} - for #{id_with_cat}"
        return Mash.new
      end
    end.call
  end

  def fetch_from_github
    return if github_repo(true).blank?
    puts "Fetching github.com/#{github_repo}"
    rest = RestClient::Resource.new(GITHUB_API_ENDPOINT, headers: { "Authorization" => "token #{Database.github_token}"})
    Mash.new JSON.parse(rest["repos/#{github_repo}"].get.body)
  end
end
