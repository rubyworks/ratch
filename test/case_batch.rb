require 'ratch/batch'

KO.case Ratch::Batch do

  def initialize
    stage_clear
    stage_fake %w{a.txt b.txt d/x.txt d/y.txt}

    @batch1 = Ratch::Batch.new('.')
    @batch2 = Ratch::Batch.new('.', '*')
    @batch3 = Ratch::Batch.new('.', '**/*')
  end

  test :local do
    @batch1.local == Pathname.new('.')
  end

  test :list do
    @batch1.list.is_a?(Array)
  end

  test :file_list do
    @batch1.file_list.is_a?(Ratch::FileList)
  end

  test :each do
    r = []
    @batch2.each{ |pn| r << pn }
    r.map(&:to_s).sort == %w{a.txt b.txt d}
  end

  test "passes #each thru to Enumerable methods" do
    @batch2.all?{ |pn| pn.is_a? Pathname }
  end

  test :size do
    batch = Ratch::Batch.new('.', '*')
    batch.size == 3
  end

  test :directory? do
    batch = Ratch::Batch.new('.', '*')
    not batch.directory?
  end

  test :file? do
    not @batch2.file?
  end

  test :directory! do
    batch = Ratch::Batch.new('.', '*')
    batch.directory!
    batch.filenames == %w{d}
  end

  test :file! do
    batch = Ratch::Batch.new('.', '*')
    batch.file!
    batch.filenames.sort == %w{a.txt b.txt}
  end

end

