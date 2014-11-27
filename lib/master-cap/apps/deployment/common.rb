
require 'json'

Capistrano::Configuration.instance.load do

  set :deploy_via, :remote_cache
  set :copy_exclude, ['.git']
  set :use_sudo, false
  set :ssh_options, { :forward_agent => true }

  JSON.parse(File.read(ENV['TOPOLOGY'])).each do |server_name, config|
    if config["no_release"]
      server server_name, *config["roles"], :no_release => true
    else
      server server_name, *config["roles"]
    end
  end

  if exists? :http_proxy
    default_run_options[:env] = {
      'http_proxy' => http_proxy,
      'https_proxy' => http_proxy,
    }
  end

  ENV['LOAD_INTO_CAP'].split(':').each do |f|
    # puts "Load #{f}"
    load f
  end

  task :purge_cached_directory_if_remote_change, :roles => :app do
    cache = "#{shared_path}/cached-copy"
    run "if [ -d #{cache} ]; then cd #{cache} && git remote -v | grep origin | grep #{repository} || (echo Purging cached copy #{cache}; rm -rf #{cache}); fi"
  end

  before 'deploy:update', :purge_cached_directory_if_remote_change

end

