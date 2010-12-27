require 'ratch/batch'

KO.case Ratch::Batch do

  test :initialize do
    Ratch::Batch.new('.')
    Ratch::Batch.new('.', '*')
    Ratch::Batch.new('.', '**/*')
  end

  test :each do
    batch = Ratch::Batch.new('.', '*')
    batch.all?{ |pn| pn.is_a? Pathname }
  end

end

