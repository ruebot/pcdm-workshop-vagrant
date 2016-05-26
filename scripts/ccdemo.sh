#!/bin/sh

rails new ccdemo --skip-spring
cd ccdemo
echo "gem 'curation_concerns', github:'projecthydra-labs/curation_concerns', branch: 'master'" >> Gemfile
bundle install
yes Y | rails generate curation_concerns:install
rake db:migrate
rails generate curation_concerns:work Book

sed -i 's|8984.*|8080 %>/fcrepo/rest|' config/fedora.yml

echo "
task :ccdemo do
  SolrWrapper.wrap( config: '.solr_wrapper') do |solr|
    solr.with_collection(name: 'hydra-development', dir: File.join('solr', 'config')) do
      IO.popen('rails server -b 0.0.0.0') do |io|
        begin
          io.each do |line|
            puts line
          end
        rescue Interrupt
          puts 'Stopping server'
        end
      end
    end
  end
end" >> Rakefile
