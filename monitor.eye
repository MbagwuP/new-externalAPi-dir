APP_ROOT = File.expand_path('.', File.dirname(__FILE__)) unless defined? APP_ROOT
RACK_ENV = ENV['RACK_ENV'] || 'development'
QUEUE = ENV['QUEUE'] || 'notification_callback_queue'
TERM_CHILD = '1'
WORKERS = (ENV['WORKERS'] || '1').to_i

Eye.config do
  logger "#{APP_ROOT}/log/eye.log"
end

Eye.application 'externalapi' do

  working_dir APP_ROOT

  env 'RACK_ENV' => RACK_ENV
  env 'TERM_CHILD' => TERM_CHILD
  env 'QUEUE' => QUEUE

  group 'resque' do
    chain grace: 5.seconds

    WORKERS.times do |i|
      process "worker-#{i}" do
        pid_file "tmp/externalapi-worker-#{i}.pid"
        start_command "bundle exec rake resque:work"
        stop_command "kill -QUIT {PID}"
        daemonize true
      end
    end

  end

end