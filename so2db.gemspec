require 'rake'

Gem::Specification.new do |s|
  s.name = 'so2db'
  s.version = '0.1.0'
  s.date = '2012-08-08'
  s.summary = 'StackOverflow Data Dump Import Utilities'
  s.description = <<-EOF
    SO2DB provides an API for building StackOverflow data dump importers.  It
    ships with a PostgreSQL implementation and binary.
  EOF
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables << 'so2pg'
  s.author = 'Chad Taylor'
  s.email = 'caepo3@gmail.com'
  s.license = 'MIT'
  s.files = FileList['lib/**/*.rb',
                     'bin/*',
                     '[A-Z]*',
                     'test/**/*'].to_a
  s.test_files = Dir.glob('test/*.rb')
  s.homepage = 'https://github.com/tessellator/so2db'

  s.add_runtime_dependency 'activerecord'
  s.add_runtime_dependency 'foreigner'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'pg'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
end
