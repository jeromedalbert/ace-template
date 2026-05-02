.tap { |logger| logger.formatter = ->(severity, _, _, msg) { "#{severity} #{msg}\n" } }
