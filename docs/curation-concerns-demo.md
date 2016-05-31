This is a guided tour of CurationConcerns, including the built-in functionality
and the parts that can be customized to add new fields and functionality.

* originally presented at the dc fedora users group, 2016-04-28, and part of the stock
[curation concerns vagrant documentation](https://github.com/projecthydra-labs/curation-concerns-vagrant/wiki/Dive-Into-Curation-Concerns).

## the hydra/curation concerns stack
CurationConcerns uses a new set of components collaboratively developed by the Hydra community:
* AF (the core of the traditional Hydra stack) provides ActiveRecord-style modeling for Fedora
* Hydra::PCDM provides the basic PCDM classes and relationships
* Hydra::Works adds Works and FileSets, plus a Swiss Army Knife of repository functionality
* CurationConcerns adds a Rails engine, views, controllers, etc.
* Sufia 7 is rebuilding Sufia on top of CurationConcerns, and adds dashboards, reporting, and other IR functionality

## a note about solr_wrapper and fcrepo_wrapper
this VM uses solr_wrapper for curation_concerns instead of a more traditional Tomcat-based or
standalone Solr setup.
* standard hydra test/development infrastructure
* downloads solr quickly spin up with minimal config
* **do not use in production: it deletes data by default**

## production infrastructure
for a production setup, you would have a host of other concerns that are not easily accommodated with solr_wrapper and fcrepo_wrapper.
* fedora
  * separate machine with tomcat or jetty
  * files on network storage
  * relational database for metadata
  * event-based workflow
* solr
  * solr 5+ standalone app
  * might be shared with other applications
  * fast disk and/or enough memory to keep index in memory

## start vagrant environment

* start the vagrant environment following instructions in the [README](../README.md).

* start the curation-concerns-demo application

    ```
    $ vagrant ssh
    $ cd ccdemo
	$ rake ccdemo
    ```

## stock curation concerns

  [http://localhost:3000/](http://localhost:3000/)

* demo of unmodified curation concerns
  * create an account
    * click Sign In
    * click create an account
    * fill out your email and desired password
    * click Create an account and your account will be created and you will be signed in  
  * add an object
    * click the + in the toolbar to get a menu of items you can create
    * click Create a Book
    * you can add basic dublin core metadata
    * you can attach a file 
    * visibility options including embargo, lease, institutional access
    * click Create Book button at the bottom
      * the Book object is created with the properties you added
      * the file is uploaded
      * background processing runs FITS, generates derivatives, etc.
      * once your object is created, see the thumbnail, metadata, you can view the files, etc.
  * search, facet, view, download
    * search for your object's title
    * standard Blacklight search results page
    * some facets configured
* behind the scenes
  * fedora view of an object: [http://localhost:8080/fcrepo/rest/](http://localhost:8080/fcrepo/rest/)
    * go to fedora and click on `dev` to see the objects created
    * objects for your Book, any File(s) you attached, plus more for WebAC access control
    * search for your newly-created object's ID to see your Book's object
    * metadata as RDF properties, links to the file with `pcdm:hasMember`
    * membership proxies in `members` child container
    * ordering with ORE Proxies in `list_source` child container
  * solr view of an object: [http://localhost:8983/solr/hydra-development/select](http://localhost:8983/solr/hydra-development/select)
    * use the solr admin tool or add `?q=id:[your Book's ID]` to the url
    * see the properties mapped to solr fields

## customizing curation concerns
* basic customization
  * adding a property to a model
  * adding to edit and show forms
* as we look at how to customize CurationConcerns, explain how the framework is organized
  * models, views, controllers
    * very common application framework pattern, with models for the core data, views for the user interface, and controllers in the middle handling logic
  * forms, indexers, presenters
    * address gaps in model-view-controller framework: form objects help building editing forms, indexers/presenters map to/from Solr

## adding a copyright property
* model defines the property
* form wraps the model
* view provides HTML UI for the create/edit form

## add a property to the Book model
#### app/models/book.rb
```
  class Book < ActiveFedora::Base
    include ::CurationConcerns::WorkBehavior
    include ::CurationConcerns::BasicMetadata
    validates :title, presence: { message: 'Your work must have a title.' }
+   property :copyright, predicate: ::RDF::URI('http://www.loc.gov/premis/rdf/v1#hasCopyrightStatus')
  end
```

## add the property to the Book form 
#### app/forms/curation_concerns/book_form.rb
```
  module CurationConcerns
    class BookForm < CurationConcerns::Forms::WorkForm
      self.model_class = ::Book
+     delegate :copyright, to: :model
+     self.terms += [:copyright]
    end
  end
```

## create a custom view for create/edit forms
#### app/views/curation_concerns/books/_form_additional_information.html.erb
```
+ <fieldset class="optional prompt">
+   <legend>Additional Information</legend>
+   <%= f.input :subject,         as: :multi_value, input_html: { class: 'form-control' } %>
+   <%= f.input :publisher,       as: :multi_value, input_html: { class: 'form-control' } %>
+   <%= f.input :source,          as: :multi_value, input_html: { class: 'form-control' } %>
+   <%= f.input :language,        as: :multi_value, input_html: { class: 'form-control' } %>
+   <%= f.input :copyright,       as: :multi_value, input_html: { class: 'form-control' } %>
+ </fieldset>
```

## create or edit a record to see the new field
* create or edit a record
* add a copyright value
* view the copyright value in fedora
* but it doesn't show up in solr

## indexing in Solr
* indexer maps from the model to Solr
* model defines which indexer to use

## create a custom indexer
$ mkdir app/indexers
#### app/indexers/book_indexer.rb
```
+ class BookIndexer < CurationConcerns::WorkIndexer
+   def generate_solr_document
+     super.tap do |solr_doc|
+       Solrizer.set_field(solr_doc, 'copyright', object.copyright, :displayable)
+     end
+   end
+ end
```

## update the Book model to use the custom indexer
#### app/models/book.rb
```
  class Book < ActiveFedora::Base
    include ::CurationConcerns::WorkBehavior
    include ::CurationConcerns::BasicMetadata
    validates :title, presence: { message: 'Your work must have a title.' }
    property :copyright, predicate: ::RDF::URI('http://www.loc.gov/premis/rdf/v1#hasCopyrightStatus')
+   def self.indexer
+     ::BookIndexer
+   end
  end
```

## update the object and check the solr index
* update the object to trigger reindexing
* view the copyright field in solr
* still not showing up on the show page

## showing to end users
* presenter maps from Solr to the form
* controller defines which presenter to use 
* view provides HTML UI

## create a custom presenter
$ mkdir app/presenters
# app/presenters/book_presenter.rb
```
+ class BookPresenter < CurationConcerns::WorkShowPresenter
+   delegate :copyright, to: :solr_document
+ end
```

## map the field in to solr
#### app/models/solr_document.rb
```
  ...
+   def copyright
+     fetch('copyright_ssm', [])
+   end
  end
```

## tell the controller to use the custom presenter
#### app/controllers/curation_concerns/books_controller.rb
```
  class CurationConcerns::BooksController < ApplicationController
    include CurationConcerns::CurationConcernController
    self.curation_concern_type = Book
+   def show_presenter
+     ::BookPresenter
+   end
  end
```

## add the property to the show view
#### app/views/curation_concerns/books/_attribute_rows.html.erb
```
+ <%= presenter.attribute_to_html(:description) %>
+ <%= presenter.attribute_to_html(:creator, catalog_search_link: true ) %>
+ <%= presenter.attribute_to_html(:contributor, label: 'Contributors', catalog_search_link: true) %>
+ <%= presenter.attribute_to_html(:subject, catalog_search_link: true) %>
+ <%= presenter.attribute_to_html(:publisher) %>
+ <%= presenter.attribute_to_html(:language) %>
+ <%= presenter.attribute_to_html(:copyright) %>
```

## reload the record to see the copyright field
* reload the show page
* see the copyright value displayed to end users

## adding a facet
* update the indexer to index as facetable
* update the search controller to display the facet

## update the indexer to make copyright facetable
#### app/indexers/book_indexer.rb
```
  class BookIndexer < CurationConcerns::WorkIndexer
    def generate_solr_document
      super.tap do |solr_doc|
-       Solrizer.set_field(solr_doc, 'copyright', object.copyright, :displayable)
+       Solrizer.set_field(solr_doc, 'copyright', object.copyright, :displayable, :facetable)
      end
    end
  end
```

## tell the controller to use the facet
#### app/controllers/catalog_controller.rb
```
  class CatalogController < ApplicationController
    include CurationConcerns::CatalogController
    configure_blacklight do |config|
      ...
      config.add_facet_field solr_name('based_near', :facetable), limit: 5
      config.add_facet_field solr_name('publisher', :facetable), limit: 5
      config.add_facet_field solr_name('file_format', :facetable), limit: 5
      config.add_facet_field 'generic_type_sim', show: false, single: true
+     config.add_facet_field solr_name('copyright', :facetable), limit: 5, label: 'Copyright'
      ...
  end
```

## update a record and search to view the facet
* update a record with copyright
* perform a search
* see copyright facet in the sidebar

## acknowledgments
thanks to justin coyne for great tutorials:

* http://projecthydra.github.io/training/deeper_into_hydra/
* http://jcoyne.github.io/forms_presenters_indexers/
