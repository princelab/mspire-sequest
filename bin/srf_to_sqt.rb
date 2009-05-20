#!/usr/bin/env ruby

require 'tap'
require 'ms/sequest/srf/sqt'

class Ms::Sequest::Srf::Srftosqt < Tap::Task

  def self.parse!(argv=ARGV, app=Tap::App.instance)
    opts = ConfigParser.new

    unless configurations.empty?
      opts.separator "configurations:"
      opts.add(configurations)
      opts.separator ""
    end

    opts.separator "options:"

    # add option to print help
    opts.on("--help", "Print this help") do
      prg = case $0
            when /rap$/ then 'rap'
            else 'tap run --'
            end

      puts "#{help}usage: #{File.basename(__FILE__)} <file>.srf ..."
      puts "outputs: <file>.sqt ..."
      puts          
      puts opts
      exit
    end

    # add option to specify the task name
    name = default_name
    opts.on('--name NAME', 'Specifies the task name') do |value|
      name = value
    end

    # add option to specify a config file
    config_path = nil
    opts.on('--config FILE', 'Specifies a config file') do |value|
      config_path = value
    end

    # add option to load args to ARGV
    use_args = []
    opts.on('--use FILE', 'Loads inputs to ARGV') do |path|
      use(path, use_args)
    end

    # parse!
    argv = opts.parse!(argv, {}, false)

    # load configurations
    config = load_config(config_path)

    # build and reconfigure the instance
    instance = new({}, name, app).reconfigure(config).reconfigure(opts.nested_config)

    [instance, (argv + use_args)]
  end
end

if ARGV.size == 0
  ARGV << "--help"
end

instance, args = Ms::Sequest::Srf::Srftosqt.parse!(ARGV)
instance.execute(*args)

