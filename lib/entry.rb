require 'rest-client'
require 'toml'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/enumerable'
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
    h.crates_io = fetch_from_crates_io
    h.github = fetch_from_github
    h.cargo_toml = fetch_cargo_toml
    return h
  end

  # A dumb algorithm to rank projects for a category
  # Pretty sure there are better ways to do this, and if you know one,
  # let me know!
  #
  # Weight is a number between 0 and 1.
  # Higher the weight, higher it floats (weird, I know)
  #
  # Currently weight is affected by GitHub stars, forks, and crates.io
  # downloads
  # Stars affect 80% of the weight
  # Forks and Downloads affect 10% each
  def weight max_stars, max_forks, max_downloads
    if max_stars.zero?
      stars = 0.0
    else
      stars = weight_stars.to_f / max_stars
    end
    if max_forks.zero?
      forks = 0.0
    else
      forks = weight_forks.to_f / max_forks
    end
    if max_downloads.zero?
      downloads = 0.0
    else
      downloads = crates_io_downloads.to_f / max_downloads
    end
    @weights = [(stars * 0.8), (forks * 0.1), (downloads * 0.1)]
    @weights.sum
  end

  # for debugging purposes
  def calculated_weights
    @weights
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

  def cargo_toml_cache
    cache.cargo_toml!
  end

  def name 
    @payload.name || crate_cache.name.to_s.titlecase.presence || @id
  end

  def description
    @payload.description.presence ||
      crate_cache.description.presence ||
      cargo_toml_cache.package!.description.presence ||
      github_cache.description
  end

  def crates_io_downloads
    crate_cache.downloads.to_i
  end

  def licence
    crate_cache.license.presence ||
      cargo_toml_cache.package!.license
  end

  def version
    crate_cache.max_version.presence ||
      cargo_toml_cache.package!.version
  end

  def github_full_name
    github_cache.full_name
  end

  def github_forks
    github_cache.forks.to_i
  end

  def github_stars
    github_cache.stargazers_count.to_i
  end

  def weight_stars
    # if the project is on BitBucket, multiply it by 1.5 as BitBucket
    # projects usually receive less exposure
    #
    # also need to think about what to do with projects which are not
    # on GH/BB, maybe assign them manual stars?
    github_stars
  end

  def weight_forks
    github_forks
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
    @payload.homepage_url.presence ||
      crate_cache.homepage.presence ||
      cargo_toml_cache.package!.homepage.presence ||
      repository_url ||
      crate_url
  end

  def repository_url
    @payload.repository_url || crate_cache.repository
  end

  def has_github?
    repository_url =~ /github\.com/
  end

  def crate_url
    if crates_io_id
      "https://crates.io/crates/#{crates_io_id}"
    end
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
        puts "crates.io is not available for #{id_with_cat}"
        return Mash.new
      end
      puts "Fetching crates.io/#{crates_io_id}"
      begin
        rest = RestClient::Resource.new(CRATES_IO_API_ENDPOINT)
        return Mash.new JSON.parse(rest["crates/#{crates_io_id}"].get.body)
      rescue RestClient::ResourceNotFound => e
        puts "[ERROR] #{e.class} - #{e.message} - for #{id_with_cat} while fetching crates.io/#{crates_io_id}"
        return Mash.new
      end
    end.call
  end

  def fetch_from_github
    rest_for_github_repo do |rest|
      puts "Fetching github.com/#{github_repo}"
      Mash.new JSON.parse(rest["repos/#{github_repo}"].get.body)
    end
  end

  # TODO: Add support for raw urls to TOML files
  def fetch_cargo_toml
    rest_for_github_repo do |rest|
      puts "Fetching Cargo.toml from github.com/#{github_repo}"
      Mash.new(
        TOML.parse(
          Base64.decode64(
            JSON.parse(rest["repos/#{github_repo}/contents/Cargo.toml"].get.body)["content"]
            ).force_encoding('UTF-8')
          )
        )
    end
  rescue RestClient::ResourceNotFound => e
    puts "Cargo.toml was not found for #{id_with_cat}"
    return Mash.new
  end

  def rest_for_github_repo
    return Mash.new if github_repo(true).blank?
    yield RestClient::Resource.new(GITHUB_API_ENDPOINT, headers: { "Authorization" => "token #{Database.github_token}"})
  end
end
