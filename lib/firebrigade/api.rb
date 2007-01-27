require 'digest/md5'

require 'rubygems'
require 'rc_rest'
require 'firebrigade'

class Firebrigade::API < RCRest

  class Error < RCRest::Error; end

  class InvalidLogin < Error; end

  class NotFound < Error; end

  class WrongAPIVersion < Error; end

  VERSION = '1.0.0'

  API_VERSION = '1.0.0'

  Build = Struct.new :id, :successful, :duration, :created_on, :version_id,
                     :target_id

  Owner = Struct.new :id, :name

  Project = Struct.new :id, :name, :owner_id

  Target = Struct.new :id, :version, :release_date, :platform, :username

  Version = Struct.new :id, :name, :project_id

  def initialize(host, username, password)
    @username = username
    @password = password
    @url = URI.parse "http://#{host}/api/REST/"
  end

  def add_build(version_id, target_id, successful, duration, log)
    post_multipart :add_build, :version_id => version_id,
                               :target_id => target_id,
                               :successful => successful, :duration => duration,
                               :log => log
  end

  def add_owner(name)
    post :add_owner, :name => name
  end

  def add_project(name, owner_id)
    post :add_project, :name => name, :owner_id => owner_id
  end

  def add_target(version, release_date, platform)
    post :add_target, :version => version, :release_date => release_date,
                      :platform => platform, :api_version => API_VERSION
  end

  def add_version(name, project_id)
    post :add_version, :name => name, :project_id => project_id
  end

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

  def get_build(version_id, target_id)
    get :get_build, :version_id => version_id, :target_id => target_id
  end

  def get_owner(name)
    get :get_owner, :name => name
  end

  def get_project(name, owner_id)
    get :get_project, :name => name, :owner_id => owner_id
  end

  def get_target(version, release_date, platform)
    get :get_target, :version => version, :release_date => release_date,
                     :platform => platform, :username => @username,
                     :api_version => API_VERSION
  end

  def get_version(name, project_id)
    get :get_version, :name => name, :project_id => project_id
  end

  def make_multipart(params) # :nodoc:
    set_hash params

    super params
  end

  def make_url(method, params) # :nodoc:
    set_hash params if method.to_s =~ /^add_/

    super method, params
  end

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

  def set_hash(params)
    param_values = params.sort_by { |n| n.to_s }.map do |name, value|
      "#{name}=#{URI.escape value.to_s}"
    end.join '&'
    
    hash = Digest::MD5.hexdigest "#{param_values}:#{@username}:#{@password}"

    params[:hash] = hash
    params[:user] = @username
  end

end

