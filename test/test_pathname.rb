require 'test/unit'
require 'path/name'

class PathNameTest < Test::Unit::TestCase # :nodoc:

  def test_initialize
    p1 = Path::Name.new('a')
    assert_equal('a', p1.to_s)
    p2 = Path::Name.new(p1)
    assert_equal(p1, p2)
  end

  class AnotherStringLike # :nodoc:
    def initialize(s) @s = s end
    def to_str() @s end
    def ==(other) @s == other end
  end

  def test_equality
    obj = Path::Name.new("a")
    str = "a"
    sym = :a
    ano = AnotherStringLike.new("a")
    assert_equal(false, obj == str)
    assert_equal(false, str == obj)
    assert_equal(false, obj == ano)
    assert_equal(false, ano == obj)
    assert_equal(false, obj == sym)
    assert_equal(false, sym == obj)

    obj2 = Path::Name.new("a")
    assert_equal(true, obj == obj2)
    assert_equal(true, obj === obj2)
    assert_equal(true, obj.eql?(obj2))
  end

  def test_hashkey
    h = {}
    h[Path::Name.new("a")] = 1
    h[Path::Name.new("a")] = 2
    assert_equal(1, h.size)
  end

  def assert_pathname_cmp(e, s1, s2)
    p1 = Path::Name.new(s1)
    p2 = Path::Name.new(s2)
    r = p1 <=> p2
    assert(e == r,
      "#{p1.inspect} <=> #{p2.inspect}: <#{e}> expected but was <#{r}>")
  end
  def test_comparison
    assert_pathname_cmp( 0, "a", "a")
    assert_pathname_cmp( 1, "b", "a")
    assert_pathname_cmp(-1, "a", "b")
    ss = %w(
      a
      a/
      a/b
      a.
      a0
    )
    s1 = ss.shift
    ss.each {|s2|
      assert_pathname_cmp(-1, s1, s2)
      s1 = s2
    }
  end

  def test_comparison_string
    assert_equal(nil, Path::Name.new("a") <=> "a")
    assert_equal(nil, "a" <=> Path::Name.new("a"))
  end

  def test_syntactical
    assert_equal(true, Path::Name.new("/").root?)
    assert_equal(true, Path::Name.new("//").root?)
    assert_equal(true, Path::Name.new("///").root?)
    assert_equal(false, Path::Name.new("").root?)
    assert_equal(false, Path::Name.new("a").root?)
  end

  def test_paths
    assert_equal('/', Path::Name.new('/').to_s)
    assert_equal('a/', Path::Name.new('a/').to_s)
    assert_equal('/a', Path::Name.new('/a').to_s)
    assert_equal('.', Path::Name.new('.').to_s)
    assert_equal('..', Path::Name.new('..').to_s)
  end

  def test_cleanpath
    assert_equal('/', Path::Name.new('/').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('//').cleanpath(true).to_s)
    assert_equal('', Path::Name.new('').cleanpath(true).to_s)

    assert_equal('.', Path::Name.new('.').cleanpath(true).to_s)
    assert_equal('..', Path::Name.new('..').cleanpath(true).to_s)
    assert_equal('a', Path::Name.new('a').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('/.').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('/..').cleanpath(true).to_s)
    assert_equal('/a', Path::Name.new('/a').cleanpath(true).to_s)
    assert_equal('.', Path::Name.new('./').cleanpath(true).to_s)
    assert_equal('..', Path::Name.new('../').cleanpath(true).to_s)
    assert_equal('a/', Path::Name.new('a/').cleanpath(true).to_s)

    assert_equal('a/b', Path::Name.new('a//b').cleanpath(true).to_s)
    assert_equal('a/.', Path::Name.new('a/.').cleanpath(true).to_s)
    assert_equal('a/.', Path::Name.new('a/./').cleanpath(true).to_s)
    assert_equal('a/..', Path::Name.new('a/../').cleanpath(true).to_s)
    assert_equal('/a/.', Path::Name.new('/a/.').cleanpath(true).to_s)
    assert_equal('..', Path::Name.new('./..').cleanpath(true).to_s)
    assert_equal('..', Path::Name.new('../.').cleanpath(true).to_s)
    assert_equal('..', Path::Name.new('./../').cleanpath(true).to_s)
    assert_equal('..', Path::Name.new('.././').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('/./..').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('/../.').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('/./../').cleanpath(true).to_s)
    assert_equal('/', Path::Name.new('/.././').cleanpath(true).to_s)

    assert_equal('a/b/c', Path::Name.new('a/b/c').cleanpath(true).to_s)
    assert_equal('b/c', Path::Name.new('./b/c').cleanpath(true).to_s)
    assert_equal('a/c', Path::Name.new('a/./c').cleanpath(true).to_s)
    assert_equal('a/b/.', Path::Name.new('a/b/.').cleanpath(true).to_s)
    assert_equal('a/..', Path::Name.new('a/../.').cleanpath(true).to_s)

    assert_equal('/a', Path::Name.new('/../.././../a').cleanpath(true).to_s)
    assert_equal('a/b/../../../../c/../d',
      Path::Name.new('a/b/../../../../c/../d').cleanpath(true).to_s)
  end

  def test_cleanpath_no_symlink
    assert_equal('/', Path::Name.new('/').cleanpath.to_s)
    assert_equal('/', Path::Name.new('//').cleanpath.to_s)
    assert_equal('', Path::Name.new('').cleanpath.to_s)

    assert_equal('.', Path::Name.new('.').cleanpath.to_s)
    assert_equal('..', Path::Name.new('..').cleanpath.to_s)
    assert_equal('a', Path::Name.new('a').cleanpath.to_s)
    assert_equal('/', Path::Name.new('/.').cleanpath.to_s)
    assert_equal('/', Path::Name.new('/..').cleanpath.to_s)
    assert_equal('/a', Path::Name.new('/a').cleanpath.to_s)
    assert_equal('.', Path::Name.new('./').cleanpath.to_s)
    assert_equal('..', Path::Name.new('../').cleanpath.to_s)
    assert_equal('a', Path::Name.new('a/').cleanpath.to_s)

    assert_equal('a/b', Path::Name.new('a//b').cleanpath.to_s)
    assert_equal('a', Path::Name.new('a/.').cleanpath.to_s)
    assert_equal('a', Path::Name.new('a/./').cleanpath.to_s)
    assert_equal('.', Path::Name.new('a/../').cleanpath.to_s)
    assert_equal('/a', Path::Name.new('/a/.').cleanpath.to_s)
    assert_equal('..', Path::Name.new('./..').cleanpath.to_s)
    assert_equal('..', Path::Name.new('../.').cleanpath.to_s)
    assert_equal('..', Path::Name.new('./../').cleanpath.to_s)
    assert_equal('..', Path::Name.new('.././').cleanpath.to_s)
    assert_equal('/', Path::Name.new('/./..').cleanpath.to_s)
    assert_equal('/', Path::Name.new('/../.').cleanpath.to_s)
    assert_equal('/', Path::Name.new('/./../').cleanpath.to_s)
    assert_equal('/', Path::Name.new('/.././').cleanpath.to_s)

    assert_equal('a/b/c', Path::Name.new('a/b/c').cleanpath.to_s)
    assert_equal('b/c', Path::Name.new('./b/c').cleanpath.to_s)
    assert_equal('a/c', Path::Name.new('a/./c').cleanpath.to_s)
    assert_equal('a/b', Path::Name.new('a/b/.').cleanpath.to_s)
    assert_equal('.', Path::Name.new('a/../.').cleanpath.to_s)

    assert_equal('/a', Path::Name.new('/../.././../a').cleanpath.to_s)
    assert_equal('../../d', Path::Name.new('a/b/../../../../c/../d').cleanpath.to_s)
  end

  def test_destructive_update
    path = Path::Name.new("a")
    path.to_s.replace "b"
    assert_equal(Path::Name.new("a"), path)
  end

  #def test_null_character
  #  assert_raise(ArgumentError) { Path::Name.new("\0") }
  #end

  def assert_relpath(result, dest, base)
    assert_equal(Path::Name.new(result),
      Path::Name.new(dest).relative_path_from(Path::Name.new(base)))
  end

  def assert_relpath_err(dest, base)
    assert_raise(ArgumentError) {
      Path::Name.new(dest).relative_path_from(Path::Name.new(base))
    }
  end

  def test_relative_path_from
    assert_relpath("../a", "a", "b")
    assert_relpath("../a", "a", "b/")
    assert_relpath("../a", "a/", "b")
    assert_relpath("../a", "a/", "b/")
    assert_relpath("../a", "/a", "/b")
    assert_relpath("../a", "/a", "/b/")
    assert_relpath("../a", "/a/", "/b")
    assert_relpath("../a", "/a/", "/b/")

    assert_relpath("../b", "a/b", "a/c")
    assert_relpath("../a", "../a", "../b")

    assert_relpath("a", "a", ".")
    assert_relpath("..", ".", "a")

    assert_relpath(".", ".", ".")
    assert_relpath(".", "..", "..")
    assert_relpath("..", "..", ".")

    assert_relpath("c/d", "/a/b/c/d", "/a/b")
    assert_relpath("../..", "/a/b", "/a/b/c/d")
    assert_relpath("../../../../e", "/e", "/a/b/c/d")
    assert_relpath("../b/c", "a/b/c", "a/d")

    assert_relpath("../a", "/../a", "/b")
    assert_relpath("../../a", "../a", "b")
    assert_relpath(".", "/a/../../b", "/b")
    assert_relpath("..", "a/..", "a")
    assert_relpath(".", "a/../b", "b")

    assert_relpath("a", "a", "b/..")
    assert_relpath("b/c", "b/c", "b/..")

    assert_relpath_err("/", ".")
    assert_relpath_err(".", "/")
    assert_relpath_err("a", "..")
    assert_relpath_err(".", "..")
  end

  def assert_pathname_plus(a, b, c)
    a = Path::Name.new(a)
    b = Path::Name.new(b)
    c = Path::Name.new(c)
    d = b + c
    assert(a == d,
      "#{b.inspect} + #{c.inspect}: #{a.inspect} expected but was #{d.inspect}")
  end

  def test_plus
    assert_pathname_plus('a/b', 'a', 'b')
    assert_pathname_plus('a', 'a', '.')
    assert_pathname_plus('b', '.', 'b')
    assert_pathname_plus('.', '.', '.')

    assert_pathname_plus('/', '/', '..')
    assert_pathname_plus('.', 'a', '..')
    assert_pathname_plus('a', 'a/b', '..')
    assert_pathname_plus('../..', '..', '..')
    assert_pathname_plus('/c', '/', '../c')
    assert_pathname_plus('c', 'a', '../c')
    assert_pathname_plus('a/c', 'a/b', '../c')
    assert_pathname_plus('../../c', '..', '../c')

    # TODO: Is this really what we want?
    assert_pathname_plus('/b', 'a', '/b')
  end

  def test_taint
    obj = Path::Name.new("a"); assert_same(obj, obj.taint)
    obj = Path::Name.new("a"); assert_same(obj, obj.untaint)

    assert_equal(false, Path::Name.new("a"      )           .tainted?)
    assert_equal(false, Path::Name.new("a"      )      .to_s.tainted?)
    assert_equal(true,  Path::Name.new("a"      ).taint     .tainted?)
    assert_equal(true,  Path::Name.new("a"      ).taint.to_s.tainted?)
    assert_equal(true,  Path::Name.new("a".taint)           .tainted?)
    assert_equal(true,  Path::Name.new("a".taint)      .to_s.tainted?)
    assert_equal(true,  Path::Name.new("a".taint).taint     .tainted?)
    assert_equal(true,  Path::Name.new("a".taint).taint.to_s.tainted?)

    str = "a"
    path = Path::Name.new(str)
    str.taint
    assert_equal(false, path     .tainted?)
    assert_equal(false, path.to_s.tainted?)
  end

  def test_untaint
    obj = Path::Name.new("a"); assert_same(obj, obj.untaint)

    assert_equal(false, Path::Name.new("a").taint.untaint     .tainted?)
    assert_equal(false, Path::Name.new("a").taint.untaint.to_s.tainted?)

    str = "a".taint
    path = Path::Name.new(str)
    str.untaint
    assert_equal(true, path     .tainted?)
    assert_equal(true, path.to_s.tainted?)
  end

  def test_freeze
    obj = Path::Name.new("a"); assert_same(obj, obj.freeze)

    assert_equal(false, Path::Name.new("a"       )            .frozen?)
    assert_equal(false, Path::Name.new("a".freeze)            .frozen?)
    assert_equal(true,  Path::Name.new("a"       ).freeze     .frozen?)
    assert_equal(true,  Path::Name.new("a".freeze).freeze     .frozen?)
    assert_equal(false, Path::Name.new("a"       )       .to_s.frozen?)
    assert_equal(false, Path::Name.new("a".freeze)       .to_s.frozen?)
    assert_equal(false, Path::Name.new("a"       ).freeze.to_s.frozen?)
    assert_equal(false, Path::Name.new("a".freeze).freeze.to_s.frozen?)
  end

  def test_to_s
    str = "a"
    obj = Path::Name.new(str)
    assert_equal(str, obj.to_s)
    assert_not_same(str, obj.to_s)
    assert_not_same(obj.to_s, obj.to_s)
  end

  def test_kernel_open
    count = 0
    stat1 = File.stat(__FILE__)
    result = Kernel.open(Path::Name.new(__FILE__)) {|f|
      stat2 = f.stat
      assert_equal(stat1.dev, stat2.dev)
      assert_equal(stat1.ino, stat2.ino)
      assert_equal(stat1.size, stat2.size)
      count += 1
      2
    }
    assert_equal(1, count)
    assert_equal(2, result)
  end

end

