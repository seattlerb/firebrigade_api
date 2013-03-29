Firebrigade API

by Eric Hodel

http://seattlerb.rubyforge.org/firebrigade_api

== DESCRIPTION

An API wrapper for http://firebrigade.seattlerb.org

== FEATURES/PROBLEMS

* Fully wraps Firebrigade API
* Provides friendly cache for implementing applications like Tinderbox
* No way to retrieve build log (easy with OpenURI)
* No way to query for owners/projects/etc.  (Not implemented in API.)

== SYNOPSIS

  require 'rubygems'
  require 'firebrigade/api'
  
  fa = Firebrigade::API.new 'firebrigade.seattlerb.org', 'username', 'password'

== REQUIREMENTS

* rc-rest
* Connection to firebrigade.seattlerb.org

== INSTALL

* sudo gem install firebrigade_api

