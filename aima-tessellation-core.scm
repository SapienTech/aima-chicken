(define n-vertices (make-parameter 100))

(define-record node
  @("Data structure for graphs"
    (state "An indexable point")
    (parent "The node-predecessor")
    (action "Not used")
    (path-cost "Cost of the path up to this point"))
  state
  parent
  action
  path-cost)

(R-apply "library" '(deldir))

(define (R-voronoi n-vertices)
  (R-apply "$" (list
                (R-apply "deldir"
                         (list (R-apply "rnorm" (list n-vertices))
                               (R-apply "rnorm" (list n-vertices))))
                "dirsgs")))

(define (voronoi R-voronoi)
  (R-eval "apply" R-voronoi 1 (R-apply "get" '("list"))))

(define-record-and-printer point x y)

(define (voronoi-for-each f voronoi)
  (vector-for-each
   (lambda (i x)
     (match x
       (#(#(x1 y1 x2 y2 i1 i2 e1 e2))
        (f x1 y1 x2 y2))))
   voronoi))

(define (neighbors voronoi)
  (let ((neighbors (make-hash-table)))
    (voronoi-for-each
     (lambda (x1 y1 x2 y2)
       (let ((p1 (make-point x1 y1))
             (p2 (make-point x2 y2)))
         (hash-table-update!/default neighbors
                                     p1
                                     (lambda (neighbors)
                                       (lset-adjoin eq? neighbors p2))
                                     '())
         (hash-table-update!/default neighbors
                                     p2
                                     (lambda (neighbors)
                                       (lset-adjoin eq? neighbors p1))
                                     '())))
     voronoi)
    neighbors))

(define (points neighbors)
  (hash-table-keys neighbors))

(define (start points)
  (let iter ((points points)
             (start (make-point +inf +inf)))
    (if (null? points)
        start
        (let ((point (car points))
              (rest (cdr points)))
          (if (< (point-x point) (point-x start))
              (iter rest point)
              (iter rest start))))))

(define (end points)
  (let iter ((points points)
             (end (make-point -inf -inf)))
    (if (null? points)
        end
        (let ((point (car points))
              (rest (cdr points)))
          (if (> (point-x point) (point-x end))
              (iter rest point)
              (iter rest end))))))

(define-record-and-printer tessellation
  @("tessellation contains point and adjacency information for a
tessellated-plane; as well as start and end nodes."
    (points "The points in the tessellation")
    (neighbors "The adjacency information for points")
    (start "The start node for the problem")
    (end "The end node for the problem"))
  R-object
  points
  neighbors
  start
  end)

(define tessellate
  @("Tessellate the plane into disjoint, convex polygons."
    (n-vertices "The numbers of vertices in the tessellation")
    (@to "tessellation"))
  (case-lambda
   (() (tessellate (n-vertices)))
   ((n-vertices)
    (let* ((R-voronoi (R-voronoi n-vertices))
           (voronoi (voronoi R-voronoi)))
      (let* ((neighbors (neighbors voronoi))
             (points (points neighbors)))
        (let ((start (start points))
              (end (end points)))
          (make-tessellation
           R-voronoi
           points
           neighbors
           start
           end)))))))

(define (point-distance p1 p2)
  @("Calculate the distance between two points."
    (p1 "The first point")
    (p2 "The second point")
    (@to "distance"))
  (sqrt (+ (expt (- (point-x p1) (point-x p2)) 2)
           (expt (- (point-y p1) (point-y p2)) 2))))

(define (make-title title path-length path-cost)
  (format "~a; length: ~a, cost: ~,2f" title path-length path-cost))

(R-apply "source" (list (make-pathname (repository-path)
                                       "aima-tessellation.R")))

(define (predecessor-path node)
  @("List the predecessors of this node."
    (node "The node to predecess")
    (@to "list"))
  (let iter ((path (list node)))
    (let ((parent (node-parent (car path))))
      (if parent
          (iter (cons parent path))
          path))))

(define (path-x path)
  (map (lambda (node) (point-x (node-state node)))
       path))

(define (path-y path)
  (map (lambda (node) (point-y (node-state node)))
       path))

(define (plot-tessellation tessellation path title filename)
  @("Plot the tessellation with its start and end nodes, as well as
the path taken from start to end."
    (tessellation "The tessellation to plot")
    (path "A list of nodes")
    (title "Title for the graph")
    (filename "The PNG to which to write"))
  (let ((title (make-title title (length path) (node-path-cost (car path)))))
    (let ((start (tessellation-start tessellation))
          (end (tessellation-end tessellation)))
      (R-eval "plot.voronoi"
              (tessellation-R-object tessellation)
              (list->vector (path-x path))
              (list->vector (path-y path))
              (point-x start)
              (point-y start)
              (point-x end)
              (point-y end)
              filename
              title))))

(define (plot-tessellation/animation tessellation path title filename)
  @("Plot the tessellation as an animation fit for YouTube."
    (tessellation "The tessellation to plot")
    (path "A list of nodes")
    (title "Title for the animation")
    (filename "A base filename, unto which will be appended `.avi'"))
  (let ((directory (create-temporary-directory)))
    (let iter ((path (reverse path))
               (i (- (length path) 1)))
      (debug i)
      (if (null? path)
          (begin
            ;; TODO: Use `shell' instead.
            (system* "convert $(find ~a -type f | sort -k 1.~a -n) $(yes $(find ~a -type f | sort -k 1.~a -n | tail -n 1) | head -n 10) -loop 0 ~a.gif"
                     directory
                     (+ (string-length directory) 2)
                     directory
                     (+ (string-length directory) 2)
                     filename)
            (system* "mencoder ~a.gif -ovc lavc -o ~a.avi"
                     filename
                     filename))
          (begin
            (plot-tessellation
             tessellation
             path
             title
             (make-pathname directory (format "~a.png" i)))
            (iter (cdr path) (- i 1)))))))
(define (join-animations output . animations)
  (run (mencoder -ovc copy -idx -o ,output ,@animations)))
