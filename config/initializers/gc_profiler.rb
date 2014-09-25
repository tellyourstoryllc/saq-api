GC::Profiler.enable unless %w(development test).include?(Rails.env)
