#!/usr/bin/env ruby

require 'tap'
require 'ms/sequest/srf/sqt'

instance, args = Ms::Sequest::Srf::Srftosqt.parse!(ARGV)
instance.execute(*args)

