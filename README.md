# Crease-Pattern

Crease-pattern implements a format for working with origami crease patterns. It has the property that each crease pattern has exactly one possible representation (but see caveats below).
It explicitly records the full lines that the line segments on a pattern lie on, which I believe will make checking the similarity of two patterns easier.

### Specification
See SPEC.md for the specification of the format.

### Library

The crease-pattern library provides the following structs:
* the `(line s1 d1 s2 d2 segments)` struct, where `s1`-`d2` are the sides and distances of the two points as explained in SPEC.md and `segments` is a `set` of segments
* the `(segment d1 d2 type)` struct, where `d1` and `d2` are the start and stop points of the segment and `type` is the type as a symbol (`'M`,`'V` or `'U`)
See SPEC.md for the meanings of the arguments. A set of `line`s is a crease pattern, which can be used with the following functions:
* `(cp->jsexpr <crease pattern>)` and `(jsexpr->cp <jsexpr>)` convert between crease patterns and jsexprs of the json representation defined in SPEC.md
* `(cp->cartesian-segments <crease pattern>)` takes a crease pattern to a list of lists in the form `(<x1> <y1> <x2> <y2> <type>)`, specifying the segments in cartesian coordinates (useful for drawing them for instance)
* `(cp-shared-lines <crease pattern 1> <crease pattern 2>)` returns a list of the list in the form `(<s1> <d1> <s2> <d2>)` representing the lines that exist in both patterns
* `(cp-compose <crease pattern 1> <crease pattern 2>)` returns a new crease pattern with all the segments of both input patterns with any overlapping or touching lines merged, or `#f` if there are overlapping lines of different types so such a composition is impossible
* `(cp->svg <crease pattern>)` returns the xml of an svg representing the crease pattern as a string

### Caveats
* I can't actually prove that all patterns have exactly one representation, there may be edge cases I haven't thought of
* To the extent that it actually does have that property, it's to a significant extent achieved just by restricting possible values of each section
