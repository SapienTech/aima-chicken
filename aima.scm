(module aima
  (compose-environments
   make-debug-environment
   make-step-limited-environment
   make-performance-measuring-environment
   simulate)

  (import chicken
          data-structures
          extras
          scheme
          srfi-1)

  (use debug
       foof-loop)

  (define (simulate environment)
    (loop ((while (environment)))))

  (define (compose-environments . environments)
    (lambda ()
      (every identity (map (lambda (environment)
                             (environment))
                           environments))))

  (define (make-performance-measuring-environment
           measure-performance
           score-update!)
    (lambda () (score-update! (measure-performance))))

  (define (make-step-limited-environment steps)
    (let ((current-step 0))
      (lambda ()
        (set! current-step (+ current-step 1))
        (< current-step steps))))

  (define make-debug-environment
    (case-lambda
     ((object) (make-debug-environment object pp))
     ((object display)
      (lambda () (display object))))))
