require 'test/unit'
require 'rubygems'
require 'rc_rest/net_http_stub'
require 'rc_rest/uri_stub'

require 'firebrigade/cache'

class Firebrigade::Cache
  attr_accessor :owners, :projects, :versions
end

class TestFirebrigadeCache < Test::Unit::TestCase

  def setup
    Net::HTTP.params = []
    Net::HTTP.paths = []
    Net::HTTP.responses = []

    URI::HTTP.uris = []
    URI::HTTP.responses = []

    @spec = Gem::Specification.new
    @spec.name = 'gem_one'
    @spec.version = '0.0.2'
    @spec.rubyforge_project = 'gem'

    @fc = Firebrigade::Cache.new 'firebrigade.example.com', 'username',
                                 'password'
  end

  def test_get_build_id
    URI::HTTP.responses << <<-EOF
<ok>
  <build>
    <id>5</id>
    <created_on>#{Time.now}</created_on>
    <duration>1.5</duration>
    <successful>true</successful>
    <target_id>4</target_id>
    <version_id>3</version_id>
  </build>
</ok>
    EOF

    assert_equal 5, @fc.get_build_id(3, 4)

    assert_equal 'http://firebrigade.example.com/api/REST/get_build?target_id=4&version_id=3',
                 URI::HTTP.uris.shift

    URI::HTTP.responses << <<-EOF
<error>
  <message>No such build exists</message>
</error>
    EOF

    assert_equal nil, @fc.get_build_id(-1, 4)

    assert_equal 'http://firebrigade.example.com/api/REST/get_build?target_id=4&version_id=-1',
                 URI::HTTP.uris.shift
  end

  def test_get_target_id
    Net::HTTP.responses << <<-EOF
<ok>
  <target>
    <id>5</id>
    <platform>fake platform</platform>
    <release_date>fake release_date</release_date>
    <username>fake username</username>
    <version>fake version</version>
  </target>
</ok>
    EOF

    assert_equal 5, @fc.get_target_id
  end

  def test_get_version_id_cached
    @fc.owners['gem'] = 1
    @fc.projects[[1, 'gem_one']] = 2
    @fc.versions[[2, '0.0.2']] = 3

    version_id = @fc.get_version_id @spec
    assert_equal 3, version_id
  end

  def test_get_version_id_no_data
    Net::HTTP.responses << <<-EOF
<ok>
  <owner>
    <id>1</id>
    <name>gem</name>
  </owner>
</ok>
    EOF

    Net::HTTP.responses << <<-EOF
<ok>
  <project>
    <id>2</id>
    <name>gem_one</name>
    <owner_id>1</owner_id>
  </project>
</ok>
    EOF

    Net::HTTP.responses << <<-EOF
<ok>
  <version>
    <id>3</id>
    <name>0.0.2</name>
    <project_id>2</project_id>
  </version>
</ok>
    EOF

    version_id = @fc.get_version_id @spec
    assert_equal 3, version_id

    assert_equal 1, @fc.owners['gem']
    assert_equal 2, @fc.projects[[1, 'gem_one']]
    assert_equal 3, @fc.versions[[2, '0.0.2']]

    assert_equal 3, Net::HTTP.paths.length

    assert_equal '/api/REST/add_owner', Net::HTTP.paths.shift
    assert_equal '/api/REST/add_project', Net::HTTP.paths.shift
    assert_equal '/api/REST/add_version', Net::HTTP.paths.shift

    assert_equal 3, Net::HTTP.params.length

    assert_equal 'hash=6e434d0379ccd7ac7d22dbd7923b5ea6&name=gem&user=username',
                 Net::HTTP.params.shift
    assert_equal 'hash=749f7b36b1cf1a274bbcd805c3a42a50&name=gem_one&owner_id=1&user=username',
                 Net::HTTP.params.shift
    assert_equal 'hash=67467aef2fdc65b98c80778301e2eff1&name=0.0.2&project_id=2&user=username',
                 Net::HTTP.params.shift
  end

end

