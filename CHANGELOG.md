## 1.0.0

### New Features

* Adds support for mongoid 5

### Major Changes (Backwards Incompatible)

* Drops support for mongoid 3

* An optional tenant is now automatically set if a current tenant is defined.

* A unique constraint with an optional tenant now uses the client scoping. An item cannot be shared if another client item has the same value.