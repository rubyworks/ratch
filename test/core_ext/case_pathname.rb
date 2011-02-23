require 'ratch/core_ext'

# Test the Pathname extensions.
KO.case 'Pathname' do

  # Test some standard pathname features to ensure nothing is screwed up.

  test :initialize do
    p1 = Pathname.new('a')
    p2 = Pathname.new(p1)
    p1 == p2 && 'a' == p1.to_s
  end

  test :== do |obj2|
    obj1 = Pathname.new("a")
    obj2 = Pathname.new("a")
    obj1 == obj2
  end

  test :=== do
    obj1 = Pathname.new("a")
    obj2 = Pathname.new("a")
    obj1 === obj2
  end

  test :eql? do
    obj1 = Pathname.new("a")
    obj2 = Pathname.new("a")
    obj1.eql?(obj2)
  end


  class AnotherStringLike # :nodoc:
    def initialize(s) @s = s end
    def to_str() @s end
    def ==(other) @s == other end
  end

  test 'equality' do
    obj = Pathname.new("a")
    str = "a"
    sym = :a
    ano = AnotherStringLike.new("a")
    return false if obj == str
    return false if str == obj
    return false if obj == ano
    return false if ano == obj
    return false if obj == sym
    return false if sym == obj
    return true
  end

  test :hash do
    h = {}
    h[Pathname.new("a")] = 1
    h[Pathname.new("a")] = 2
    h.size == 1
  end

  test :<=> do |e, s1, s2|
    p1 = Pathname.new(s1)
    p2 = Pathname.new(s2)
    e == (p1 <=> p2)
  end

  ok  0, "a", "a"
  ok  1, "b", "a"
  ok -1, "a", "b"

  ok -1, "a", "a/"
  ok -1, "a/", "a/b"
  ok -1, "a/b", "a."
  ok -1, "a.", "a0"

  test :<=> do
    (Pathname.new("a") <=> "a").nil? &&
    ("a" <=> Pathname.new("a")).nil?
  end

  test :root do |a|
    Pathname.new(a).root?
  end

  ok '/'
  ok '//'
  ok '///'

  no ''
  no 'a'

  test :to_s do |a,b|
    a == Pathname.new(b).to_s
  end

  ok '/' , '/'
  ok 'a/', 'a/'
  ok '/a', '/a'
  ok '.' , '.'
  ok '..', '..'

  test :cleanpath do |a,b|
    a == Pathname.new(b).cleanpath(true).to_s
  end

  ok '/' , '/'
  ok '/' , '//'
  ok '/' , '/.'
  ok '/' , '/..'
  ok '/', '/./..'
  ok '/', '/../.'
  ok '/', '/./../'
  ok '/', '/.././'

  ok '.' , '.'
  ok '.' , './'

  ok '..', '..'
  ok '..', '../'
  ok '..', './..'
  ok '..', '../.'
  ok '..', './../'
  ok '..', '.././'

  ok 'a'   , 'a'
  ok 'a/'  , 'a/'
  ok 'a/.' , 'a/.'
  ok 'a/.' , 'a/./'
  ok 'a/..', 'a/../'
  ok 'a/..', 'a/../.'

  ok '/a'  , '/a'
  ok '/a/.', '/a/.'

  ok 'a/b'  , 'a//b'
  ok 'a/b/c', 'a/b/c'
  ok 'b/c'  , './b/c'
  ok 'a/c'  , 'a/./c'
  ok 'a/b/.', 'a/b/.'

  ok '/a', '/../.././../a'
  ok 'a/b/../../../../c/../d', 'a/b/../../../../c/../d'

=begin
  def test_cleanpath_no_symlink
    assert_equal('/', Pathname.new('/').cleanpath.to_s)
    assert_equal('/', Pathname.new('//').cleanpath.to_s)
    assert_equal('', Pathname.new('').cleanpath.to_s)

    assert_equal('.', Pathname.new('.').cleanpath.to_s)
    assert_equal('..', Pathname.new('..').cleanpath.to_s)
    assert_equal('a', Pathname.new('a').cleanpath.to_s)
    assert_equal('/', Pathname.new('/.').cleanpath.to_s)
    assert_equal('/', Pathname.new('/..').cleanpath.to_s)
    assert_equal('/a', Pathname.new('/a').cleanpath.to_s)
    assert_equal('.', Pathname.new('./').cleanpath.to_s)
    assert_equal('..', Pathname.new('../').cleanpath.to_s)
    assert_equal('a', Pathname.new('a/').cleanpath.to_s)

    assert_equal('a/b', Pathname.new('a//b').cleanpath.to_s)
    assert_equal('a', Pathname.new('a/.').cleanpath.to_s)
    assert_equal('a', Pathname.new('a/./').cleanpath.to_s)
    assert_equal('.', Pathname.new('a/../').cleanpath.to_s)
    assert_equal('/a', Pathname.new('/a/.').cleanpath.to_s)
    assert_equal('..', Pathname.new('./..').cleanpath.to_s)
    assert_equal('..', Pathname.new('../.').cleanpath.to_s)
    assert_equal('..', Pathname.new('./../').cleanpath.to_s)
    assert_equal('..', Pathname.new('.././').cleanpath.to_s)
    assert_equal('/', Pathname.new('/./..').cleanpath.to_s)
    assert_equal('/', Pathname.new('/../.').cleanpath.to_s)
    assert_equal('/', Pathname.new('/./../').cleanpath.to_s)
    assert_equal('/', Pathname.new('/.././').cleanpath.to_s)
    return false unless obj.equal? obj.taint
    assert_equal('a/b/c', Pathname.new('a/b/c').cleanpath.to_s)
    assert_equal('b/c', Pathname.new('./b/c').cleanpath.to_s)
    assert_equal('a/c', Pathname.new('a/./c').cleanpath.to_s)
    assert_equal('a/b', Pathname.new('a/b/.').cleanpath.to_s)
    assert_equal('.', Pathname.new('a/../.').cleanpath.to_s)

    assert_equal('/a', Pathname.new('/../.././../a').cleanpath.to_s)
    assert_equal('../../d', Pathname.new('a/b/../../../../c/../d').cleanpath.to_s)
  end
=end

=begin
  def test_destructive_update
    path = Pathname.new("a")
    path.to_s.replace "b"
    assert_equal(Pathname.new("a"), path)
  end
=end

  #def test_null_character
  #  assert_raise(ArgumentError) { Pathname.new("\0") }
  #end

  test :relative_path_from do |result, dest, base|
    Pathname.new(result) == Pathname.new(dest).relative_path_from(Pathname.new(base))
  end

  ok "../a", "a", "b"
  ok "../a", "a", "b/"
  ok "../a", "a/", "b"
  ok "../a", "a/", "b/"
  ok "../a", "/a", "/b"
  ok "../a", "/a", "/b/"
  ok "../a", "/a/", "/b"
  ok "../a", "/a/", "/b/"

  ok "../b", "a/b", "a/c"
  ok "../a", "../a", "../b"

  ok "a", "a", "."
  ok "..", ".", "a"

  ok ".", ".", "."
  ok ".", "..", ".."
  ok "..", "..", "."

  ok "c/d", "/a/b/c/d", "/a/b"
  ok "../..", "/a/b", "/a/b/c/d"
  ok "../../../../e", "/e", "/a/b/c/d"
  ok "../b/c", "a/b/c", "a/d"

  ok "../a", "/../a", "/b"
  ok "../../a", "../a", "b"
  ok ".", "/a/../../b", "/b"
  ok "..", "a/..", "a"
  ok ".", "a/../b", "b"

  ok "a", "a", "b/.."
  ok "b/c", "b/c", "b/.."

  test :relative_path_from do |dest, base|
    ArgumentError.raised? {
      Pathname.new(dest).relative_path_from(Pathname.new(base))
    }
  end

  ok "/", "."
  ok ".", "/"
  ok "a", ".."
  ok ".", ".."

  test :+ do |a, b, c|
    a = Pathname.new(a)
    b = Pathname.new(b)
    c = Pathname.new(c)
    a == b + c
  end

  ok 'a/b', 'a', 'b'
  ok 'a', 'a', '.'
  ok 'b', '.', 'b'
  ok '.', '.', '.'

  ok '/', '/', '..'
  ok '.', 'a', '..'
  ok 'a', 'a/b', '..'
  ok '../..', '..', '..'
  ok '/c', '/', '../c'
  ok 'c', 'a', '../c'
  ok 'a/c', 'a/b', '../c'
  ok '../../c', '..', '../c'

  # TODO: Is this really what we want?
  ok '/b', 'a', '/b'

  test :taint do
    obj = Pathname.new("a")
    obj.equal? obj.taint
  end

  test :untaint do
    obj = Pathname.new("a")
    obj.equal? obj.untaint
  end

  test :tainted? do
    return false if Pathname.new("a").tainted?
    return false if Pathname.new("a").to_s.tainted?
    true
  end

  test :tainted? do
    Pathname.new("a"      ).taint.tainted?       &&
    Pathname.new("a"      ).taint.to_s.tainted?  &&
    Pathname.new("a".taint)           .tainted?  &&
    Pathname.new("a".taint)      .to_s.tainted?  &&
    Pathname.new("a".taint).taint     .tainted?  &&
    Pathname.new("a".taint).taint.to_s.tainted?
  end

  test :tainted? do
    str = "a"
    path = Pathname.new(str)
    str.taint
    return false if path.tainted?
    return false if path.to_s.tainted?
    return true
  end

  test :tainted? do
    !Pathname.new("a").taint.untaint     .tainted? &&
    !Pathname.new("a").taint.untaint.to_s.tainted?
  end

  test :tainted? do
    str = "a".taint
    path = Pathname.new(str)
    str.untaint
    path.tainted? && path.to_s.tainted?
  end

  test :freeze do
    obj = Pathname.new("a")
    obj.equal? obj.freeze
  end

  test :freeze do
    Pathname.new("a"       ).freeze.frozen? &&
    Pathname.new("a".freeze).freeze.frozen?
  end

  test :freeze do
    not (
      Pathname.new("a"       )            .frozen? &&
      Pathname.new("a".freeze)            .frozen? &&
      Pathname.new("a"       )       .to_s.frozen? &&
      Pathname.new("a".freeze)       .to_s.frozen? &&
      Pathname.new("a"       ).freeze.to_s.frozen? &&
      Pathname.new("a".freeze).freeze.to_s.frozen?
    )
  end

  test :to_s do
    str = "a"
    obj = Pathname.new(str)
    str == obj.to_s &&
    !str.equal?(obj.to_s) &&
    !obj.to_s.equal?(obj.to_s)
  end

=begin
  test "kernel open" do
    count = 0
    stat1 = File.stat(__FILE__)
    result = Kernel.open(Pathname.new(__FILE__)) do |f|
      stat2 = f.stat
      assert_equal(stat1.dev, stat2.dev)
      assert_equal(stat1.ino, stat2.ino)
      assert_equal(stat1.size, stat2.size)
      count += 1
      2
    end
    assert_equal(1, count)
    assert_equal(2, result)
  end
=end

end

