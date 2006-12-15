require 'rubygems'
require 'firebrigade/api'

class Firebrigade::Cache

  def initialize(host, username, password)
    @fa = Firebrigade::API.new host, username, password

    @owners = {} # owner => owner_id
    @projects = {} # [project, owner_id] => project_id
    @versions = {} # [version, project_id] => version_id

    @targets = {} # [version, release_date, platform] => target_id
    @builds = {} # [version_id, target_id] => build_id
  end

  def get_build_id(version_id, target_id)
    build_args = [version_id, target_id]
    return @builds[build_args] if @builds.include? build_args

    begin
      build = @fa.get_build(*build_args)
      @builds[build_args] = build.id
    rescue Firebrigade::API::NotFound
      nil
    end
  end

  ##
  # Fetches or creates a target matching +version+, +release_date+ and
  # +platform+.  Returns the target's id.

  def get_target_id(version = RUBY_VERSION, release_date = RUBY_RELEASE_DATE,
                    platform = RUBY_PLATFORM)
    target_args = [version, release_date, platform]
    return @targets[target_args] if @targets.include? target_args

    target = @fa.add_target(*target_args)

    @targets[target_args] = target.id
  end

  ##
  # Fetches or creates a version (including project and owner) for +spec+.
  # Returns the version's id.

  def get_version_id(spec)
    owner = spec.rubyforge_project
    project = spec.name
    version = spec.version.to_s

    owner_id = @owners[owner]

    if owner_id.nil? then
      owner_id = @fa.add_owner(owner).id
      @owners[owner] = owner_id
    end

    project_id = @projects[[owner_id, project]]

    if project_id.nil? then
      project_id = @fa.add_project(project, owner_id).id
      @projects[[owner_id, project]] = project_id
    end

    version_id = @versions[[project_id, version]]

    if version_id.nil? then
      version_id = @fa.add_version(version, project_id).id
      @versions[[project_id, version]] = version_id
    end

    version_id
  end

end

