Object.module_eval do
  def se command
    log_info command
    exit(1) unless system command
  end

  def log_info message
    message = "[INFO]\t#{message}"
    puts message
  end

  def log_error message
    message = "[ERROR]\t#{message}"
    all_error_messages << message
    puts message
  end

  def all_error_messages
    $all_error_messages ||= []
  end
end
