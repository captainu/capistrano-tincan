Capistrano::Configuration.instance.load do

  _cset(:tincan_default_hooks) { true }

  _cset(:tincan_pid) { File.join(shared_path, 'pids', 'tincan.pid') }
  _cset(:tincan_env) { fetch(:rack_env, fetch(:rails_env, 'production')) }
  _cset(:tincan_log) { File.join(shared_path, 'log', 'tincan.log') }

  _cset(:tincan_options) { nil }

  _cset(:tincan_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec tincan" }
  _cset(:tincanctl_cmd) { "#{fetch(:bundle_cmd, 'bundle')} exec tincanctl" }

  _cset(:tincan_timeout) { 10 }
  _cset(:tincan_role) { :app }
  _cset(:tincan_processes) { 1 }

  if fetch(:tincan_default_hooks)
    before 'deploy:update_code', 'tincan:quiet'
    after 'deploy:stop', 'tincan:stop'
    after 'deploy:start', 'tincan:start'
    before 'deploy:restart', 'tincan:restart'
  end

  namespace :tincan do
    def for_each_process
      fetch(:tincan_processes).times do |idx|
        if idx.zero? && fetch(:tincan_processes) <= 1
          pid_file = fetch(:tincan_pid)
        else
          pid_file = fetch(:tincan_pid).gsub(/\.pid$/, "-#{idx}.pid")
        end
        yield(pid_file, idx)
      end
    end

    def quiet_process(pid_file, _)
      run "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:tincanctl_cmd)} quiet #{pid_file} ; else echo 'tincan is not running'; fi"
    end

    def stop_process(pid_file, _)
      run "if [ -d #{current_path} ] && [ -f #{pid_file} ] && kill -0 `cat #{pid_file}`> /dev/null 2>&1; then cd #{current_path} && #{fetch(:tincanctl_cmd)} stop #{pid_file} #{fetch :tincan_timeout} ; else echo 'tincan is not running'; fi"
    end

    def start_process(pid_file, idx)
      args = []
      args.push "--pidfile #{pid_file}"
      args.push "--environment #{fetch(:tincan_env)}"
      args.push "--logfile #{fetch(:tincan_log)}" if fetch(:tincan_log)
      args.push fetch(:tincan_options)

      if defined?(JRUBY_VERSION)
        args.push '>/dev/null 2>&1 &'
        logger.info 'Since JRuby doesn\'t support Process.daemon, tincan will not be running as a daemon.'
      else
        args.push '--daemon'
      end

      run "cd #{current_path} ; #{fetch(:tincan_cmd)} #{args.compact.join(' ')} ", pty: false
    end

    desc 'Quiet tincan (stop accepting new work)'
    task :quiet, roles: -> { fetch(:tincan_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        quiet_process(pid_file, idx)
      end
    end

    desc 'Stop tincan'
    task :stop, roles: -> { fetch(:tincan_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        stop_process(pid_file, idx)
      end
    end

    desc 'Start tincan'
    task :start, roles: -> { fetch(:tincan_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        start_process(pid_file, idx)
      end
    end

    desc 'Rolling-restart tincan'
    task :rolling_restart, roles: -> { fetch(:tincan_role) }, on_no_matching_servers: :continue do
      for_each_process do |pid_file, idx|
        stop_process(pid_file, idx)
        start_process(pid_file, idx)
      end
    end

    desc 'Restart tincan'
    task :restart, roles: -> { fetch(:tincan_role) }, on_no_matching_servers: :continue do
      stop
      start
    end
  end
end
