__DIR__ = File.dirname(__FILE__)

(Dir[File.join(__DIR__, '**/*.rb')] - [__FILE__]).each do |file|
  require file
end

