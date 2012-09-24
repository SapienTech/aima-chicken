@(heading "AIMA-Tessellation")

(module aima-tessellation
  @("aima-tessellation has procedures for tessellating a plane into
disjoint, convex polygons suitable for exercise 3.7; and then plotting
that tessellation with a path.")
  (plot-tessellation
   plot-tessellation/animation
   point-x
   point-y
   tessellate
   tessellation-points
   tessellation-neighbors
   tessellation-start
   tessellation-end)

  (import chicken scheme)

  (use aima
       debug
       files
       format
       lolevel
       matchable
       R
       srfi-1
       srfi-69
       utils
       vector-lib)

  (include "aima-tessellation-core.scm"))
