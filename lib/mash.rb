require 'hashie/mash'
require 'hashie/extensions/mash/safe_assignment'

class Mash < Hashie::Mash
  # include Hashie::Extensions::Mash::SafeAssignment
  
  def fetch! key
    send("#{key}!")
  end
end
