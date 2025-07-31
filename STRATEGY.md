Strategy
====


Design Strategy
--------
Design follows [DESIGN.md](./DESIGN.md).


Implementation Strategy
--------
Implementation should be the simplest implementation that meets specifications.
Non-simple implementations are allowed only when either security requirements or performance requirements cannot be met.


Testing Strategy
----------
Following Martin Fowler's test pyramid, comprehensive tests should be written as unit tests.
Unit tests may be omitted when they are deemed obviously correct without testing.

Integration tests will be manual E2E tests only, as update frequency is expected to be low and scenarios are straightforward.
