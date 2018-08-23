# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [2.0.2] - 2018-08-23
### Added

* Support of mongoid 7

## [2.0.1] - 2017-12-14
### Changed

* Add ensure block in method with_tenant

## [2.0] - 2017-07-21
### New Features

* Add support for mongoid 6
* Remove support for mongoid 4 & 5

## 1.2

### New Features

* Add *exclude_shared* option for the TenantUniquenessValidator

## 1.1

### New Features

* Add scopes *shared* and *unshared* (1b5c420)

### Fixes

* When a tenant is optional, do not override the tenant during persisted document initialization (81a9b45)

## 1.0.0

### New Features

* Add support for mongoid 5

### Major Changes (Backwards Incompatible)

* Drops support for mongoid 3

* An optional tenant is now automatically set if a current tenant is defined.

* A unique constraint with an optional tenant now uses the client scoping. An item cannot be shared if another client item has the same value.