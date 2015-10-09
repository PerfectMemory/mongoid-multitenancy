# mongoid-multitenancy [![Build Status](https://travis-ci.org/PerfectMemory/mongoid-multitenancy.png?branch=master)](https://travis-ci.org/PerfectMemory/mongoid-multitenancy) [![Coverage Status](https://coveralls.io/repos/PerfectMemory/mongoid-multitenancy/badge.svg?branch=master&service=github)](https://coveralls.io/github/PerfectMemory/mongoid-multitenancy?branch=master) [![Code Climate](https://codeclimate.com/github/PerfectMemory/mongoid-multitenancy.png)](https://codeclimate.com/github/PerfectMemory/mongoid-multitenancy) [![Dependency Status](https://gemnasium.com/PerfectMemory/mongoid-multitenancy.png)](https://gemnasium.com/PerfectMemory/mongoid-multitenancy)

mongoid-multitenancy adds the ability to scope [Mongoid](https://github.com/mongoid/mongoid) models to a tenant in a **shared database strategy**. Tenants are represented by a tenant model, such as `Client`. mongoid-multitenancy will help you set the current tenant on each request and ensures all 'tenant models' are always properly scoped to the current tenant: when viewing, searching and creating.

It is directly inspired by the [acts_as_tenant gem](https://github.com/ErwinM/acts_as_tenant) for Active Record.

In addition, mongoid-multitenancy:

* allows you to set the current tenant
* redefines some mongoid functions like `index`, `validates_with` and `delete_all` to take in account the multitenancy
* allows shared items between the tenants
* allows you to define an immutable tenant field once it is persisted
* is thread safe.

Installation
===============

Add this line to your application's Gemfile:

    gem 'mongoid-multitenancy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid-multitenancy

Usage
===============

There are two steps in adding multi-tenancy to your app with acts_as_tenant:

1. setting the current tenant and
2. scoping your models.

Setting the current tenant
--------------------------
There are two ways to set the current tenant: (1) by setting the current tenant manually, or (2) by setting the current tenant for a block.

**Setting the current tenant in a controller, manually**

```ruby
Mongoid::Multitenancy.current_tenant = client_instance
```

Setting the current_tenant yourself requires you to use a before_filter to set the Mongoid::Multitenancy.current_tenant variable.

**Setting the current tenant for a block**

```ruby
Mongoid::Multitenancy.with_tenant(client_instance) do
  # Current tenant is set for all code in this block
end
```

This approach is useful when running background processes for a specified tenant. For example, by putting this in your worker's run method,
any code in this block will be scoped to the current tenant. All methods that set the current tenant are thread safe.

**Note:** If the current tenant is not set by one of these methods, mongoid-multitenancy will apply a global scope to your models, not related to any tenant. So make sure you use one of the two methods to tell mongoid-multitenancy about the current tenant.

Scoping your models
-------------------
```ruby
class Client
  include Mongoid::Document

  field :name, :type => String
  validates_uniqueness_of :name
end

class Article
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant(:client)

  field :title, :type => String
end
```

Adding `tenant` to your model declaration will scope that model to the current tenant **BUT ONLY if a current tenant has been set**.
The association passed to the `tenant` function must be valid.

`tenant` accepts several options:

 * :optional : set to true when the tenant is optional (default value is `false`)
 * :immutable : set to true when the tenant field is immutable (default value is `true`)
 * :class_name, etc. : all the other options will be passed to the mongoid relation

Some examples to illustrate this behavior:

```ruby
 # This manually sets the current tenant for testing purposes. In your app this is handled by the gem.
Mongoid::Multitenancy.current_tenant = Client.find_by(:name => 'Perfect Memory') # => <#Client _id:50ca04b86c82bfc125000025, :name: "Perfect Memory">

 # All searches are scoped by the tenant, the following searches will only return objects belonging to the current client.
Article.all # => all articles where client_id => 50ca04b86c82bfc125000025

 # New objects are scoped to the current tenant
article = Article.new(:title => 'New blog')
article.save # => <#Article _id: 50ca04b86c82bfc125000044, title: 'New blog', client_id: 50ca04b86c82bfc125000025>

 # It can make the tenant field immutable once it is persisted to avoid inconsistency
article.persisted? # => true
article.client = another_client
article.valid? # => false
```

**Optional tenant**

When setting an optional tenant, for example to allow shared instances between all the tenants, the default scope will return both the tenant and the free-tenant items. That means that using `Article.delete_all` or `Article.destroy_all` will **remove the shared items too**. And that means too that **the tenant must be set manually**.

```ruby
class Article
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant(:client, optional: true)

  field :title, :type => String
end

Mongoid::Multitenancy.with_tenant(client_instance) do
  Article.all # => all articles where client_id.in [50ca04b86c82bfc125000025, nil]
  article = Article.new(:title => 'New article')
  article.save # => <#Article _id: 50ca04b86c82bfc125000044, title: 'New blog', client_id: nil>

  # tenant needs to be set manually
  article.tenant = client_instance
  article.save => <#Article _id: 50ca04b86c82bfc125000044, title: 'New blog', client_id: 50ca04b86c82bfc125000025>
end
```

Rails
-------------------

If you are using Rails, you may want to set the current tenant at each request.

**Manually set the current tenant in ApplicationController using the host request**

```ruby
class ApplicationController < ActionController::Base
  before_filter :set_current_client

  def set_current_client
    current_client = Client.find_by_host(request.host)
    Mongoid::Multitenancy.current_tenant = current_client
  end
end
```

Setting the current_tenant yourself requires you to use a before_filter to set the Mongoid::Multitenancy.current_tenant variable.

Mongoid Uniqueness validators
-------------------

mongoid-multitenancy brings a TenantUniqueness validator that will, depending on the tenant options, check that your uniqueness
constraints are respected:

* When used with a *mandatory* tenant, the uniqueness constraint is scoped to the current client.

In the following case, 2 articles can have the same slug if they belongs to 2 different clients.

```ruby
class Article
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :client

  field :slug

  validates_tenant_uniqueness_of :slug
end
```

* When used with an *optional* tenant, the uniqueness constraint is not scoped if the item is shared, but is
  scoped to the client new item otherwise. Note that a private item cannot have the the value if a shared item
  already uses it.

In the following case, 2 private articles can have the same slug if they belongs to 2 different clients. But if a shared
article has the slug "slugA", no client will be able to use that slug again, like a standard validates_uniqueness_of does.

```ruby
class Article
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :client, optional: true

  field :slug

  validates_tenant_uniqueness_of :slug
end
```

Mongoid indexes
-------------------

mongoid-multitenancy automatically adds the tenant foreign key in all your mongoid indexes to avoid to redefine all your validators. If you prefer to define manually the indexes, you can use the option `full_indexes: false`.

To create a single index on the tenant field, you can use the option `index: true` like any `belongs_to` declaration (false by default)

On the example below, only one indexe will be created:

* { 'title_id' => 1, 'client_id' => 1 }

```ruby
class Article
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :client, full_indexes: true

  field :title

  index({ :title => 1 })
end
```

On the example below, 2 indexes will be created:

* { 'client_id' => 1 }
* { 'title_id' => 1 }

```ruby
class Article
  include Mongoid::Document
  include Mongoid::Multitenancy::Document

  tenant :client, index: true

  field :title

  index({ :title => 1 })
end
```

Author & Credits
----------------
mongoid-multitenancy is written by [Aymeric Brisse](https://github.com/abrisse/), from [Perfect Memory](http://www.perfect-memory.com).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
