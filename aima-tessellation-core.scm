(define n-vertices (make-parameter 100))

(define (R-voronoi n-vertices)
  (R-apply "library" '(deldir))
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
  R-object
  points
  neighbors
  start
  end)

(define tessellate
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

(define (plot-tessellation tessellation path filename)
  (R-apply "source" (list (make-pathname (repository-path)
                                         "aima-tessellation.R")))
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
            filename)))