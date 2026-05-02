# Process background jobs with Solid Queue
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
config.solid_queue.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
