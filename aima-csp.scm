@(heading "AIMA-CSP")

(module aima-csp
  @("Solver for constraint-satisfaction-problems")
  (ac-3
   backtracking-search
   backtracking-enumeration
   consistent?
   csp-constraints
   csp-domains
   csp-neighbors
   failure?
   inference
   make-csp
   neq?)

  (import scheme
          chicken)

  (use data-structures
       define-record-and-printer
       matchable
       srfi-1
       srfi-69)

  (include "aima-csp-core.scm"))
