#!/usr/bin/env ruby

require 'rubygems'
require 'ms/sequest/srf/sqt'

Ms::Sequest::Srf::Sqt.commandline(ARGV, File.basename(__FILE__))


