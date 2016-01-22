require 'lib/core_extensions'
require 'lib/database'
require 'lib/mailer'
require 'lib/path_helper'

class Runner
  include PathHelper

  class << self
    def run
      new.run
    end
  end

  def initialize
    # continue
  end

  def run
    case ARGV[0].to_s.strip
    when "expire-cache"
      expire_cache
    when "rebuild-db"
      remove_db
      build_db
    when "build-db"
      build_db
    when "deploy"
      deploy
    else
      raise "Unknown command '#{ARGV[0]}'. Valid commands are: build-db, deploy, rebuild-db, expire-cache."
    end
    log_info all_error_messages
  rescue StandardError => e
    Mailer.exception_email(e).deliver_now
    raise
  end

  def expire_cache
    cat = Category.new ARGV[1]
    entry = cat.find_entry ARGV[2]
    if not entry
      raise "Couldn't find entry #{ARGV[2].inspect} for #{ARGV[1].inspect}"
    end
    db = Database.load
    db.expire_cache(cat, entry)
    db.save
  end

  def remove_db
    se "rm -f #{db_path.to_s.inspect}"
  end

  def build_db
    Database.load.prepare.save
    Mailer.error_log_email.deliver_now
  end

  def deploy
    se "middleman build --clean"
    se "rm -rf #{gh_pages_repo_path.to_s.inspect}"
    se "mkdir -p #{gh_pages_repo_path.to_s.inspect}"
    Dir.chdir(gh_pages_repo_path) do |path|
      se "git clone #{root_path.to_s.inspect} ."
      se "git remote remove origin"
      se "git remote add origin git@github.com:webstream-io/rust-libs.git"
      se "git fetch --all"
      se "git checkout gh-pages"
      se "git reset --hard origin/gh-pages"
      se "git rm -r ."
      se "git clean -f -d"
      se "cp -R #{build_path.to_s.inspect}/* ."
      se "echo libs.rs > CNAME"
      se "git add -A"
      sha = `git show-ref origin/master`[0,8]
      se "git commit -m 'Auto commit by script/run, origin/master was at #{sha}'"
      se "git push origin gh-pages"
    end
  end
end
