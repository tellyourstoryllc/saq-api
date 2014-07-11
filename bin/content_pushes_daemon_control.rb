require 'daemons'
Daemons.run('bin/content_pushes_daemon.rb', {:dir => '../tmp/pid'})
