require 'ratch/batch'

KO.case 'Batch' do

  test :initialize do
    Ratch::Batch.new('.')
    Ratch::Batch.new('.', '*')
    Ratch::Batch.new('.', '**/*')
  end

end

