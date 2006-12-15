require 'test/unit'

require 'rubygems'
require 'rc_rest/uri_stub'
require 'rc_rest/net_http_stub'

require 'firebrigade/api'

class TestFirebrigadeAPI < Test::Unit::TestCase

  def setup
    URI::HTTP.responses = []
    URI::HTTP.uris = []

    Net::HTTP.params = []
    Net::HTTP.paths = []
    Net::HTTP.responses = []

    @fa = Firebrigade::API.new 'firebrigade.example.com', 'username', 'password'
  end

  def test_add_build
    now = Time.at Time.now.to_i

    Net::HTTP.responses << <<-EOF.strip
<ok>
  <build>
    <id>100</id>
    <created_on>#{now}</created_on>
    <duration>1.5</duration>
    <successful>true</successful>
    <target_id>100</target_id>
    <version_id>101</version_id>
  </build>
</ok>
    EOF

    build = Firebrigade::API::Build.new
    build.id = 100
    build.successful = true
    build.duration = 1.5
    build.target_id = 100
    build.created_on = now
    build.version_id = 101

    srand 0

    assert_equal build, @fa.add_build(101, 100, true, 1.5, 'did the stuff')

    assert_equal true, Net::HTTP.responses.empty?

    assert_equal 1, Net::HTTP.paths.length
    assert_equal '/api/REST/add_build', Net::HTTP.paths.first

    assert_equal 1, Net::HTTP.params.length

    expected = <<-EOF.strip
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="duration"\r
\r
1.5\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="hash"\r
\r
1a905df729030146910ddac44e6b0d67\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="log"\r
\r
did the stuff\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="successful"\r
\r
true\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="target_id"\r
\r
100\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="user"\r
\r
username\r
--ac_2f_75_c0_43_fb_c3_67\r
Content-Disposition: form-data; name="version_id"\r
\r
101\r
--ac_2f_75_c0_43_fb_c3_67--
    EOF

    assert_equal expected, Net::HTTP.params.first
  end

  def test_add_owner
    Net::HTTP.responses << <<-EOF.strip
<ok>
  <owner>
    <id>100</id>
    <name>foo</name>
  </owner>
</ok>
    EOF

    owner = Firebrigade::API::Owner.new
    owner.id = 100
    owner.name = 'foo'

    assert_equal owner, @fa.add_owner('foo')

    assert_equal true, Net::HTTP.responses.empty?

    assert_equal 1, Net::HTTP.paths.length
    assert_equal '/api/REST/add_owner', Net::HTTP.paths.first

    assert_equal 1, Net::HTTP.params.length
    assert_equal 'hash=9c5fbef18346fb68d632b625067a368a&name=foo&user=username',
                 Net::HTTP.params.first
  end

  def test_add_project
    Net::HTTP.responses << <<-EOF.strip
<ok>
  <project>
    <id>100</id>
    <name>foo</name>
    <owner_id>101</owner_id>
  </project>
</ok>
    EOF

    project = Firebrigade::API::Project.new
    project.id = 100
    project.name = 'foo'
    project.owner_id = 101

    assert_equal project, @fa.add_project('foo', 101)

    assert_equal true, Net::HTTP.responses.empty?

    assert_equal 1, Net::HTTP.paths.length
    assert_equal '/api/REST/add_project', Net::HTTP.paths.first

    assert_equal 1, Net::HTTP.params.length
    assert_equal 'hash=a623ed5872e79e8d3bede063c95a4aef&name=foo&owner_id=101&user=username',
                 Net::HTTP.params.first
  end

  def test_add_target
    Net::HTTP.responses << <<-EOF.strip
<ok>
  <target>
    <id>100</id>
    <platform>powerpc-darwin8.7.0</platform>
    <release_date>2006-08-25</release_date>
    <username>drbrain</username>
    <version>1.8.5</version>
  </target>
</ok>
    EOF

    target_platform = 'powerpc-darwin8.7.0'
    target_release_date = '2006-08-25'
    target_version = '1.8.5'

    target = Firebrigade::API::Target.new
    target.id = 100
    target.platform = 'powerpc-darwin8.7.0'
    target.release_date = '2006-08-25'
    target.version = '1.8.5'
    target.username = 'drbrain'

    assert_equal target, @fa.add_target(target_version, target_release_date,
                                        target_platform)

    assert_equal true, Net::HTTP.responses.empty?

    assert_equal 1, Net::HTTP.paths.length
    assert_equal '/api/REST/add_target', Net::HTTP.paths.first

    assert_equal 1, Net::HTTP.params.length
    assert_equal 'hash=da16057e8017ecb7b39f580c06558cf4&platform=powerpc-darwin8.7.0&release_date=2006-08-25&user=username&version=1.8.5',
                 Net::HTTP.params.first
  end

  def test_add_target_bad_hash
    Net::HTTP.responses << <<-EOF.strip
<error>
  <message>Invalid login</message>
</error>
    EOF

    e = assert_raise Firebrigade::API::InvalidLogin do
      @fa.add_target 'a', 'b', 'c'
    end

    assert_equal true, Net::HTTP.responses.empty?

    assert_equal 1, Net::HTTP.paths.length
    assert_equal '/api/REST/add_target', Net::HTTP.paths.first

    assert_equal 1, Net::HTTP.params.length
    assert_equal 'hash=c53189d0aa04121a29d957e8e264adef&platform=c&release_date=b&user=username&version=a',
                 Net::HTTP.params.first

    assert_equal 'Invalid login', e.message
  end

  def test_add_version
    Net::HTTP.responses << <<-EOF.strip
<ok>
  <version>
    <id>100</id>
    <name>1.0.0</name>
    <project_id>101</project_id>
  </version>
</ok>
    EOF

    version_name = '1.0.0'

    version = Firebrigade::API::Version.new
    version.id = 100
    version.name = version_name
    version.project_id = 101

    assert_equal version, @fa.add_version(version_name, 101)

    assert_equal true, Net::HTTP.responses.empty?

    assert_equal 1, Net::HTTP.paths.length
    assert_equal '/api/REST/add_version', Net::HTTP.paths.first

    assert_equal 1, Net::HTTP.params.length
    assert_equal 'hash=db2a1eecd0492a141b186ec5f21fea61&name=1.0.0&project_id=101&user=username',
                 Net::HTTP.params.first
  end

  def test_get_build
    now = Time.at Time.now.to_i

    URI::HTTP.responses << <<-EOF.strip
<ok>
  <build>
    <id>100</id>
    <created_on>#{now}</created_on>
    <duration>1.5</duration>
    <successful>true</successful>
    <target_id>100</target_id>
    <version_id>101</version_id>
  </build>
</ok>
    EOF

    build = Firebrigade::API::Build.new
    build.id = 100
    build.successful = true
    build.duration = 1.5
    build.target_id = 100
    build.created_on = now
    build.version_id = 101

    assert_equal build, @fa.get_build(101, 100)

    assert_equal true, URI::HTTP.responses.empty?

    assert_equal 1, URI::HTTP.uris.length
    assert_equal 'http://firebrigade.example.com/api/REST/get_build?target_id=100&version_id=101',
                 URI::HTTP.uris.first
  end

  def test_get_owner
    URI::HTTP.responses << <<-EOF.strip
<ok>
  <owner>
    <id>100</id>
    <name>foo</name>
  </owner>
</ok>
    EOF

    owner_name = 'foo'
    owner_version = '0.0.2'

    owner = Firebrigade::API::Owner.new
    owner.id = 100
    owner.name = owner_name

    assert_equal owner, @fa.get_owner(owner_name)

    assert_equal true, URI::HTTP.responses.empty?
    assert_equal 1, URI::HTTP.uris.length
    assert_equal 'http://firebrigade.example.com/api/REST/get_owner?name=foo',
                 URI::HTTP.uris.first
  end

  def test_get_project
    URI::HTTP.responses << <<-EOF.strip
<ok>
  <project>
    <id>100</id>
    <name>foo</name>
    <owner_id>101</owner_id>
  </project>
</ok>
    EOF

    project_name = 'foo'
    project_version = '0.0.2'
    project_owner_id = 101

    project = Firebrigade::API::Project.new
    project.id = 100
    project.name = project_name
    project.owner_id = project_owner_id

    assert_equal project, @fa.get_project(project_name, project_owner_id)

    assert_equal true, URI::HTTP.responses.empty?
    assert_equal 1, URI::HTTP.uris.length
    assert_equal 'http://firebrigade.example.com/api/REST/get_project?name=foo&owner_id=101',
                 URI::HTTP.uris.first
  end

  def test_get_target
    URI::HTTP.responses << <<-EOF.strip
<ok>
  <target>
    <id>100</id>
    <platform>powerpc-darwin8.7.0</platform>
    <release_date>2006-08-25</release_date>
    <username>drbrain</username>
    <version>1.8.5</version>
  </target>
</ok>
    EOF

    target_platform = 'powerpc-darwin8.7.0'
    target_release_date = '2006-08-25'
    target_username = 'drbrain'
    target_version = '1.8.5'

    target = Firebrigade::API::Target.new
    target.id = 100
    target.platform = target_platform
    target.release_date = target_release_date
    target.username = target_username
    target.version = target_version

    assert_equal target, @fa.get_target(target_version, target_release_date,
                                        target_platform)

    assert_equal true, URI::HTTP.responses.empty?
    assert_equal 1, URI::HTTP.uris.length
    assert_equal 'http://firebrigade.example.com/api/REST/get_target?platform=powerpc-darwin8.7.0&release_date=2006-08-25&username=username&version=1.8.5',
                 URI::HTTP.uris.first
  end

  def test_get_target_nonexistent
    URI::HTTP.responses << <<-EOF.strip
<error>
  <message>No such target exists</message>
</error>
    EOF

    e = assert_raises Firebrigade::API::NotFound do
      @fa.get_target 'a', 'b', 'c'
    end

    assert_equal true, URI::HTTP.responses.empty?
    assert_equal 1, URI::HTTP.uris.length
    assert_equal 'http://firebrigade.example.com/api/REST/get_target?platform=c&release_date=b&username=username&version=a',
                 URI::HTTP.uris.first

    assert_equal 'No such target exists', e.message
  end

  def test_get_version
    URI::HTTP.responses << <<-EOF.strip
<ok>
  <version>
    <id>100</id>
    <name>1.0.0</name>
    <project_id>101</project_id>
  </version>
</ok>
    EOF

    version_name = '1.0.0'

    version = Firebrigade::API::Version.new
    version.id = 100
    version.name = version_name
    version.project_id = 101

    assert_equal version, @fa.get_version(version_name, 101)

    assert_equal true, URI::HTTP.responses.empty?
    assert_equal 1, URI::HTTP.uris.length
    assert_equal 'http://firebrigade.example.com/api/REST/get_version?name=1.0.0&project_id=101',
                 URI::HTTP.uris.first
  end

end

