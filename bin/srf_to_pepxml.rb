#!/usr/bin/env ruby

require 'rubygems'
require 'mspire/sequest/srf/pepxml'

Mspire::Sequest::Srf::Pepxml.commandline(ARGV, File.basename(__FILE__))

