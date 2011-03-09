#!/usr/bin/env ruby

require 'rubygems'
require 'ms/sequest/srf/pepxml'

Ms::Sequest::Srf::Pepxml.commandline(ARGV, File.basename(__FILE__))

