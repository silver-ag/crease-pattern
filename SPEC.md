# Crease Pattern Format

Crease patterns are JSON objects. A crease pattern consists of a list of lines, each of which has a list of segments on that line which are the actual creases.
Strictly speaking, it represents a set of line segments on the unit square, each of which is Mountain, Valley or neither.

### Pattern
A Pattern is a list of Lines. No two Lines in a single Pattern may have both points equal to each other.
```
[<line1>,<line2>,...,<linen>]
```

### Line
A Line has two Points specifying the Line itself, and a list of Segments. Each point consists of a Side and a Distance. The Side is an integer 0-3 inclusive and
represents a side of the unit square, with 0 representing the top side, 1 the right, 2 the bottom and 3 the left. The Distance is a number larger than or equal to 0
and strictly smaller than 1\*, and represents a distance along that side in a clockwise direction. The Side of `point1` must be smaller than or equal to the Side of
`point2`, and if the two are equal then the Distance of `point1` must be smaller than or equal to the Distance of `point2`.\*\*

A Line also has a list of Segments. None of the Segments in the list may overlap\*\*\*, and they may only touch if they aren't the same Type\*\*\*\*.
```
{ point1: { side: <integer 0-3>,
            distance: <0-1 but not 1> },
  point2: { side: <integer 0-3>,
            distance: <0-1 but not 1> },
  segments: [<segment1>,<segment2>,...,<segmentn>] }
```

### Segments
A Segment has two Lengths, representing the proportions of the way along the parent line where the Segment starts and stops. These may be 0-1 inclusive. A Segment
also has a Type, which may be "M", "V" or "U" - standing for Mountain, Valley or Unspecified. The start Length must be less than or equal to the stop Length.
```
{ start: <0-1 inclusive>,
  stop: <0-1 inclusive>,
  type: <"M","V" or "U"> }
```

\* if they could be both 0 and 1, there would be two possible ways to represent a line that touches a corner exactly

\*\* so there's a unique representation

\*\*\* that is, none may have a Length that lies between the start and stop Lengths of any other

\*\*\*\* two Segments touch if one's stop Length is exactly equal to another's start Length. If two Segments of the same Type are permitted to touch there will be more
than one valid representation of the same crease pattern
