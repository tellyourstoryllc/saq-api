require 'daemons'
Daemons.run('bin/content_pushes_daemon.rb', {dir: '../tmp/pid', log_output: true}) # log to [pid_dir]/[app_name].output
