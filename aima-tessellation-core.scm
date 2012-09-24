(define n-vertices (make-parameter 100))

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

(define (distance p1 p2)
  (sqrt (+ (expt (- (point-x p1) (point-x p2)) 2)
           (expt (- (point-y p1) (point-y p2)) 2))))

(define (path-distance path)
  (if (= (length path) 1)
      0
      (let ((distances
             (map distance
                  (drop-right path 1)
                  (drop path 1))))
        (apply + distances))))

(define (make-title title path-distance)
  (format "~a (~,2f)" title path-distance))

(R-apply "source" (list (make-pathname (repository-path)
                                       "aima-tessellation.R")))

(define (plot-tessellation tessellation path title filename)
  @("Plot the tessellation with its start and end nodes, as well as
the path taken from start to end."
    (tessellation "The tessellation to plot")
    (path "A list of nodes")
    (filename "The PNG to which to write"))
  (let ((title (make-title title (path-distance path)))
        (path (list->vector path)))
    (let ((path-x (vector-map (lambda (i point) (point-x point)) path))
          (path-y (vector-map (lambda (i point) (point-y point)) path))
          (start (tessellation-start tessellation))
          (end (tessellation-end tessellation)))
      (R-eval "plot.voronoi"
              (tessellation-R-object tessellation)
              path-x
              path-y
              (point-x start)
              (point-y start)
              (point-x end)
              (point-y end)
              filename
              title))))
