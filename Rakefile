# -*- ruby -*-

require 'rubygems'
require 'hoe'
$LOAD_PATH.unshift 'lib'
require 'firebrigade/api'

Hoe.new 'firebrigade_api', Firebrigade::API::VERSION do |p|
  p.rubyforge_name = 'seattlerb'
  p.author = 'Eric Hodel'
  p.email = 'drbrain@segment7.net'
  p.summary = 'API for Firebrigade'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")

  p.extra_deps << ['rc-rest', '>= 2.1.0']
end

# vim: syntax=Ruby
