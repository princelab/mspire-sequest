#!/usr/bin/env ruby

require 'rubygems'
require 'mspire/sequest/srf/pepxml'

Ms::Sequest::Srf::Pepxml.commandline(ARGV, File.basename(__FILE__))

