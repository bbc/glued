# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__),'lib','glued','version.rb'])
spec = Gem::Specification.new do |s|
  s.name = 'glued'
  s.version = Glued::VERSION
  s.author = 'Simon Gregory'
  s.email = 'simon@helvector.org'
  s.homepage = 'https://github.com/simongregory/glued'
  s.platform = Gem::Platform::RUBY
  s.description = 'HDS Downloader'
  s.summary = 'Downloads and joins HTTP Dynamic Stream fragments into a single media file'
  s.license = 'MIT'
  s.files = Dir['**/*']
  s.files.reject! { |fn| fn.match /\.(DS_Store|svn|git|tmproj|gem|flv|php)|tmp|doc|segs|NOTES|scratch/ }
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'glued'
  s.add_dependency('httparty')
  s.add_dependency('nokogiri')
  s.add_development_dependency('observr')
  s.add_development_dependency('rspec')
  s.add_development_dependency('rake')
  s.post_install_message = <<EOF
Welcome to Glued
================

To download HDS delivered media pass a f4m manifest to the
tool, ie:

  glued http://royston.vasey.org/papa/lazarou.f4m

The flv file should then play in a media player such as VLC.
DRM is not removed. If the file has DRM it will only be
watchable with a Flash based player and a valid license.

Functionality is basic. The tool assumes you want the highest
quality media. Live content cannot be recorded. Multilevel
manifests are not supported, and bootstrap info has to be
embedded within the manifest.

If you try a manifest that doesn't work please open an issue
at https://github.com/simongregory/glue/issues and leave the
details.
EOF
end
