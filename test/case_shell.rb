require 'ratch/shell'

KO.case 'Shell' do

  test :initialize do
    Ratch::Shell.new
  end

end
