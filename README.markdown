Lua-CBOR
========

Lua-CBOR is a (mostly) pure Lua implementation of the
[CBOR](http://cbor.io/), a compact data serialization format,
defined in [RFC 7049](http://tools.ietf.org/html/rfc7049).
It supports Lua 5.1 until 5.3 and will utilize struct packing
and bitwise operations if available.

Obtaining the source
--------------------

Sources are available from <http://code.zash.se/lua-cbor/>.

API
---

Lua-CBOR has a similar API to many other serialization libraries, like
Lua-CJSON.

### `cbor.encode(object)`

`cbor.encode` encodes `object` into its CBOR representation and returns
that as a string.

### `cbor.decode(string)`

`cbor.decode` decodes CBOR encoded data from `string` and returns a Lua
value.

### `cbor.decode_file(file)`

`cbor.decode_file` behaves like `cbor.decode` but reads from a Lua file
handle instead of a string.  It can also read from anything that
behaves like a file handle, i.e. exposes an `:read(bytes)` method.

### `cbor.simple(value, name, [cbor])`

`cbor.simple` creates an object representing a ["simple" value][simple],
which are small (up to 255) named integers.

Two such values are pre-defined:

* `cbor.null` is used to represent the null value.
* `cbor.undefined` is used to represent the undefined value.

[simple]: http://tools.ietf.org/html/rfc7049#section-2.3

### `cbor.tagged(tag, value)`

`cbor.tagged` creates an object representing a ["tagged" value][tagged],
which is an integer attached to a value, which can be any value.

[tagged]: http://tools.ietf.org/html/rfc7049#section-2.4
