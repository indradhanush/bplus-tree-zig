# B+ Tree

A [B+ tree](https://en.wikipedia.org/wiki/B%2B_tree) implementation in [Zig](https://ziglang.org/).


## Status

WIP

## Goals

- [ ] Cacheable
- [ ] Persistent
- [ ] Configurable to match disk page size
- [ ] Thread safe for concurrent reads and writes
- [ ] Optional sibling pointers for fast traversal of leaf nodes during read operations
- [ ] Support data larger than page size (overflow)

## Resources

- [Database Internals by Alex Petrov](https://nvbn.github.io/2020/02/26/database-book/)
