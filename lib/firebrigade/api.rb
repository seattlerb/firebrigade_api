require 'digest/md5'

require 'rubygems'
require 'rc_rest'
require 'firebrigade'

##
# Firebrigade::API is an API for submitting build information to
# http://firebrigade.seattlerb.org/
#
# All #get_ and #add_ methods return an instance of the Object fetched or
# created, so get_target will return a Target object.
#
# All #add_ methods will return an instance of a pre-existing Object if one
# already exists.

class Firebrigade::API < RCRest

  ##
  # API error base class

  class Error < RCRest::Error; end

  ##
  # Raised when you supply bad login information.

  class InvalidLogin < Error; end

  ##
  # Raised when the thing you're looking for isn't there.

  class NotFound < Error; end

  ##
  # Raised when your API version is incompatible with Firebrigade's

  class WrongAPIVersion < Error; end

  ##
  # The version of Firebrigade::API you are using

  VERSION = '1.0.0'

  ##
  # Supported Firebrigade API version.

  API_VERSION = '1.0.0'

  ##
  # A Build contains information on a test run.

  Build = Struct.new :id, :successful, :duration, :created_on, :version_id,
                     :target_id

  ##
  # An Owner contains information on a Project's owner.  (A project in
  # seattlerb's firebrigade.)

  Owner = Struct.new :id, :name

  ##
  # A Project contains information about a project.  (A gem in seattlerb's
  # firebrigade.)

  Project = Struct.new :id, :name, :owner_id

  ##
  # A Target contains information about the test platform.

  Target = Struct.new :id, :version, :release_date, :platform, :username

  ##
  # A Version contains the version information for a Project.

  Version = Struct.new :id, :name, :project_id

  ##
  # Creates a new Firebrigade::API that will connect to +host+ with +username+
  # and +password+.

  def initialize(host, username, password)
    @username = username
    @password = password
    @url = URI.parse "http://#{host}/api/REST/"
  end

  ##
  # Adds a Build with +version_id+ and +target_id+, reporting the +successful+
  # status, the +duration+ taken, and the +log+.

  def add_build(version_id, target_id, successful, duration, log)
    post_multipart :add_build, :version_id => version_id,
                               :target_id => target_id,
                               :successful => successful, :duration => duration,
                               :log => log
  end

  ##
  # Adds an Owner with +name+.

  def add_owner(name)
    post :add_owner, :name => name
  end

  ##
  # Adds a Project with +name+ owned by +owner_id+.

  def add_project(name, owner_id)
    post :add_project, :name => name, :owner_id => owner_id
  end

  ##
  # Adds a Target with a Ruby +version+, Ruby +release_date+ and Ruby
  # +platform+.

  def add_target(version, release_date, platform)
    post :add_target, :version => version, :release_date => release_date,
                      :platform => platform, :api_version => API_VERSION
  end

  ##
  # Adds Version +name+ to +project_id+.

  def add_version(name, project_id)
    post :add_version, :name => name, :project_id => project_id
  end

  ##
  # Checks for errors in +xml+ and raises an appropriate Exception.

  def check_error(xml) # :nodoc:
    error = xml.elements['/error/message']
    return unless error

    case error.text
    when /No such \w+ exists/ then raise NotFound, error.text
    when 'Invalid login'      then raise InvalidLogin, error.text
    when /Your API version/   then raise WrongAPIVersion, error.text
    else                           raise Error, error.text
    end
  end

  ##
  # Retrieves a Build for +version_id+ and +target_id+.

  def get_build(version_id, target_id)
    get :get_build, :version_id => version_id, :target_id => target_id
  end

  ##
  # Retrieves an Owner matching +name+.

  def get_owner(name)
    get :get_owner, :name => name
  end

  ##
  # Retrieves a Project matching +name+ and +owner_id+.

  def get_project(name, owner_id)
    get :get_project, :name => name, :owner_id => owner_id
  end

  ##
  # Retrieves a Target matching +version+, +release_date+ and +platform+.

  def get_target(version, release_date, platform)
    get :get_target, :version => version, :release_date => release_date,
                     :platform => platform, :username => @username,
                     :api_version => API_VERSION
  end

  ##
  # Retrieves a Version matching +name+ nad +project_id+.

  def get_version(name, project_id)
    get :get_version, :name => name, :project_id => project_id
  end

  ##
  # Makes a multipart POST from +params+.

  def make_multipart(params) # :nodoc:
    set_hash params

    super params
  end

  ##
  # Makes a URL for +method+ and +params+.

  def make_url(method, params) # :nodoc:
    set_hash params if method.to_s =~ /^add_/

    super method, params
  end

  ##
  # Creates an Object from +xml+.

  def parse_response(xml) # :nodoc:
    ok = xml.elements['/ok']
    raise RCRest::Error, xml.to_s if ok.nil?
    child = ok.elements[1]
    obj = nil

    case child.name
    when 'build' then
      obj = Build.new
      obj.id = child.elements['id'].text.to_i
      obj.successful = child.elements['successful'].text == 'true'
      obj.duration = child.elements['duration'].text.to_f
      obj.target_id = child.elements['target_id'].text.to_i
      obj.version_id = child.elements['version_id'].text.to_i
      obj.created_on = Time.parse child.elements['created_on'].text
    when 'owner' then
      obj = Owner.new
      obj.id = child.elements['id'].text.to_i
      obj.name = child.elements['name'].text
    when 'project' then
      obj = Project.new
      obj.id = child.elements['id'].text.to_i
      obj.name = child.elements['name'].text
      obj.owner_id = child.elements['owner_id'].text.to_i
    when 'target' then
      obj = Target.new
      obj.id = child.elements['id'].text.to_i
      obj.platform = child.elements['platform'].text
      obj.release_date = child.elements['release_date'].text
      obj.username = child.elements['username'].text
      obj.version = child.elements['version'].text
    when 'version' then
      obj = Version.new
      obj.id = child.elements['id'].text.to_i
      obj.name = child.elements['name'].text
      obj.project_id = child.elements['project_id'].text.to_i
    else
      raise "don't know how to create a #{child.name}"
    end

    obj
  rescue NoMethodError
    puts $!
    puts $!.backtrace.join("\n\t")
    puts
    puts xml
    raise
  end

  ##
  # Sets the request hash value for +params+.

  def set_hash(params)
    param_values = params.sort_by { |n| n.to_s }.map do |name, value|
      "#{name}=#{URI.escape value.to_s}"
    end.join '&'

    hash = Digest::MD5.hexdigest "#{param_values}:#{@username}:#{@password}"

    params[:hash] = hash
    params[:user] = @username
  end

end

