### Crease-Pattern

Crease-pattern implements a format for working with origami crease patterns. It has the property that each crease pattern has exactly one possible representation (but see caveats below).
It explicitly records the full lines that the line segments on a pattern lie on, which I believe will make checking the similarity of two patterns easier.

# Specification
See SPEC.md for the specification of the format.

# Caveats
* I can't actually prove that all patterns have exactly one representation, there may be edge cases I haven't thought of
* To the extent that it actually does have that property, it's to a significant extent achieved just by restricting possible values of each section
