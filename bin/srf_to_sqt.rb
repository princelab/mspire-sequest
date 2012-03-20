#!/usr/bin/env ruby

require 'rubygems'
require 'mspire/sequest/srf/sqt'

Mspire::Sequest::Srf::Sqt.commandline(ARGV, File.basename(__FILE__))


