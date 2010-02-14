# This is the base Moonshine Manifest class, which provides a simple system
# for loading moonshine recpies from plugins, a template helper, and parses
# several configuration files:
#
#   config/moonshine.yml
#
# The contents of <tt>config/moonshine.yml</tt> are expected to serialize into
# a hash, and are loaded into the manifest's Configatron::Store.
#
#   config/database.yml
#
# The contents of your database config are parsed and are available at
# <tt>configuration[:database]</tt>.
#
# If you'd like to create another 'default rails stack' using other tools that
# what Moonshine::Manifest::Rails uses, subclass this and go nuts.
class Moonshine::Manifest < ShadowPuppet::Manifest

  # Load a Moonshine Plugin
  #
  #   class MyManifest < Moonshine::Manifest
  #
  #     # Evals vendor/plugins/moonshine_my_app/moonshine/init.rb
  #     plugin :moonshine_my_app
  #
  #     # Evals lib/my_recipe.rb
  #     plugin 'lib/my_recipe.rb'
  #
  #     ...
  #   end
  def self.plugin(name = nil)
    if name.is_a?(Symbol)
      path = rails_root.join('vendor', 'plugins', 'moonshine_' + name.to_s, 'moonshine', 'init.rb').to_s
    else
      path = name
    end
    Kernel.eval(File.read(path), binding, path)
    true
  end

  # The working directory of the Rails application this manifests describes.
  def self.rails_root
   @rails_root ||= Pathname.new(ENV["RAILS_ROOT"] || Dir.getwd).expand_path
  end

  def self.moonshine_yml
    rails_root.join('config', 'moonshine.yml')
  end

  def self.database_yml
    rails_root.join('config', 'database.yml')
  end

  # The current Rails environment
  def self.rails_env
    ENV["RAILS_ENV"] || 'production'
  end

  # The current environment's database configuration
  def database_environment
   configuration[:database][rails_env.to_sym]
  end

  # The current deployment target. Best when used with capistrano-ext's multistage settings.
  def self.deploy_stage
    ENV['DEPLOY_STAGE'] || 'undefined'
  end

  # Delegate missing methods to class, so we don't have to have so many convience methods
  def method_missing(method, *args, &block)
    if self.class.respond_to?(method)
      self.class.send(method, *args, &block)
    else
      super
    end
  end

  def respond_to?(method, include_private = false)
    super || self.class.respond_to?(method, include_private)
  end

  # Only run tasks on the specified deploy_stage.
  #
  # You can call it with the exact stage you want to run on:
  #
  #  on_stage(:my_stage) do
  #    puts "I'm on my_stage"
  #  end
  #
  # Or you can pass an array of stages to run on:
  #
  #  on_stage(:my_stage, :my_other_stage) do
  #    puts "I'm on one of my stages"
  #  end
  #
  # Or you can run a task unless it is on a stage:
  #
  #  on_stage(:unless => :my_stage) do
  #    puts "I'm not on my_stage"
  #  end
  #
  # Or you can run a task unless it is on one of several stages:
  #
  #  on_stage(:unless => [:my_stage, :my_other_stage]) do
  #    puts "I'm not on my stages"
  #  end
  def on_stage(*args)
    options = args.extract_options!
    if_opt = options[:if]
    unless_opt = options[:unless]

    unless if_opt || unless_opt
      if_opt = args
    end

    if if_opt && if_opt.is_a?(Array) && if_opt.map {|x| x.to_s}.include?(deploy_stage)
      yield
    elsif if_opt && (if_opt.is_a?(String) || if_opt.is_a?(Symbol)) && deploy_stage == if_opt.to_s
      yield
    elsif unless_opt && unless_opt.is_a?(Array) && !unless_opt.map {|x| x.to_s}.include?(deploy_stage)
      yield
    elsif unless_opt && (unless_opt.is_a?(String) || unless_opt.is_a?(Symbol)) && deploy_stage != unless_opt.to_s
      yield
    end
  end

  # Render the ERB template located at <tt>pathname</tt>. If a template exists
  # with the same basename at <tt>RAILS_ROOT/app/manifests/templates</tt>, it
  # is used instead. This is useful to override templates provided by plugins
  # to customize application configuration files.
  def template(pathname, b = binding)
    template_contents = nil
    basename = pathname.index('/') ? pathname.split('/').last : pathname
    if File.exist?(File.expand_path(File.join(rails_root, 'app', 'manifests', 'templates', basename)))
      template_contents = File.read(File.expand_path(File.join(rails_root, 'app', 'manifests', 'templates', basename)))
    elsif File.exist?(File.expand_path(pathname))
      template_contents = File.read(File.expand_path(pathname))
    else
      raise LoadError, "Can't find template #{pathname}"
    end
    ERB.new(template_contents).result(b)
  end

  # config/moonshine.yml
  if moonshine_yml.exist?
    configure(YAML::load(ERB.new(moonshine_yml.read).result))
  end


  # config/moonshine/#{rails_env}.yml
  env_config = rails_root.join('config', 'moonshine', rails_env + '.yml')
  if env_config.exist?
    configure(YAML::load(ERB.new(env_config.read).result))
  end

  # database config
  if database_yml.exist?
    configure(:database => YAML::load(ERB.new(database_yml.read).result))
  end

  # gems
  gems_yml = rails_root.join('config', 'gems.yml')
  if gems_yml.exist?
    configure(:gems => (YAML.load_file(gems_yml) rescue nil))
  end
end
