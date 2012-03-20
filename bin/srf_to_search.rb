#!/usr/bin/env ruby

require 'rubygems'
require 'mspire/sequest/srf/search'

Mspire::Sequest::Srf::Search.commandline(ARGV, File.basename(__FILE__))

