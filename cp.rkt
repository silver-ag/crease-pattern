#lang racket

;; TODO: more helpful error messages for invalid lines and segements
;; TODO: replace set->list with something that definitely garauntees order
;; TODO: composing overlapping lines where one is U should replace the overlapped section with the other type

(require predicates)

;;;;;;;;;;;;
;; structs
;;;;

(struct line
  (s1 d1 ;; s in {0,1,2,3}, s1 <= s2 [side of unit square, clockwise from top]
   s2 d2 ;; 0<=d<1, if s1=s2 then d1<=d2 [length clockwise along side]
   segments) ;; list of segments
  #:guard (λ (s1 d1 s2 d2 segments name)
            (if (and (member s1 '(0 1 2 3)) (member s2 '(0 1 2 3)) ;; check conditions above
                     (<= 0 d1) (< d1 1) (<= 0 d2) (< d2 1)
                     ((all? segment?) segments)
                     (foldl (λ (s prev)
                              (cond ;; segments aren't overlapping, out of order or uneccesarily divided (ie. 0 0.5 M, 0.5 1 M isn't allowed)
                                [(> (segment-d1 s) (car prev)) (cons (segment-d2 s)
                                                                     (segment-type s))]
                                [(= (segment-d1 s) (car prev)) (if (equal? (segment-type s)
                                                                           (cdr prev))
                                                                   (raise "invalid list of segments (adjacent segments of same type should be merged)")
                                                                   (cons (segment-d2 s)
                                                                         (segment-type s)))]
                                [else (raise (format "invalid list of segments (overlapping or out of order): ~a" segments))]))
                            (cons 0 'not-a-type) segments)
                     (or (< s1 s2) ;; ensure smaller-numbered point specified first
                         (and (= s1 s2)
                              (<= d1 d2)))) 
                (values s1 d1 s2 d2 segments)
                (raise "invalid line")))
  #:transparent)

(struct segment
  (d1 d2 ;; 0<=d<=1, d1 <= d2 [proportion of the way along the line from start point]
   type) ;; {'M, 'V, 'U} [mountain, valley or unspecified]
  #:guard (λ (d1 d2 type name) ;; check constraints
            (if (and (<= 0 d1) (<= d1 1) (<= 0 d2) (<= d2 1)
                     (<= d1 d2)
                     (member type '(M V U)))
                (values d1 d2 type)
                (raise "invalid segment")))
  #:transparent)

;;;;;;;;;;;;;;;
;; operations
;;;;

(define (cp->svg cp #:size [size 100] #:show-full-lines? [show-full-lines? #f])
  ;; show-full-lines? adds grey lines along the whole lengths that the segments lie on
  (format "<svg height=~a width=~a>~a</svg>"
          size size
          (apply string-append
                 (append
                  (if show-full-lines?
                      (map (λ (l)
                             (apply format
                                    `("<line x1=~a y1=~a x2=~a y2=~a stroke=darkgrey></line>"
                                      ,@(map (curry * size)
                                             (line-coord->cartesian (line-s1 l) (line-d1 l)))
                                      ,@(map (curry * size)
                                             (line-coord->cartesian (line-s2 l) (line-d2 l))))))
                             (set->list cp))
                      '())
                  (map (λ (l)
                         (format "<line x1=~a y1=~a x2=~a y2=~a stroke=~a></line>"
                                 (* size (first l)) (* size (second l))
                                 (* size (third l)) (* size (fourth l))
                                 (hash-ref (hash 'V "blue" 'M "red" 'U "black") (fifth l))))
                       (cp->cartesian-segments cp))))))

(define (cp-compose cp1 cp2)
  ;; combines two cps, or returns #f if they can't be combined because of overlapping lines of opposite types
  (if (equal? cp1 (set))
      cp2
      (let* [[l1 (set-first cp1)]
             [l2 (cp-line-on cp2 (line-s1 l1) (line-d1 l1) (line-s2 l1) (line-d2 l1))]
             [segments-cp1 (line-segments l1)]
             [segments-cp2 (if l2 (line-segments l2) '())]
             [new-segments (line-compose segments-cp1 segments-cp2)]]
        (if new-segments
            (cp-compose (set-remove cp1 l1) (set-add (if l2 (set-remove cp2 l2) cp2)
                                                         (line (line-s1 l1) (line-d1 l1)
                                                               (line-s2 l1) (line-d2 l1)
                                                               new-segments)))
            #f))))

(define (cp-shared-lines cp1 cp2)
  ;; returns list of (s1 d1 s2 d2)s of lines that exist in both cps
  (map (λ (l) (list (line-s1 l) (line-d1 l)
                    (line-s2 l) (line-d2 l)))
       (filter line?
               (set-map cp1 (λ (l) (cp-line-on cp2
                                               (line-s1 l) (line-d1 l)
                                               (line-s2 l) (line-d2 l)))))))

;;;;;;;;;;;;;;;;;;;;;
;; helper functions
;;;;

(define (cp->cartesian-segments cp)
  ;; returns (x1 y1 x2 y2 type)
  ;; approach: to get (eg) the x at point d% along a line, take the x at the start and add d% of the difference between the start and end
  (apply append
         (map (λ (l)
                (let* [[p1 (line-coord->cartesian (line-s1 l) (line-d1 l))]
                       [p2 (line-coord->cartesian (line-s2 l) (line-d2 l))]
                       [dx (- (first p2) (first p1))]
                       [dy (- (second p2) (second p1))]]
                  (map (λ (s)
                         (list (+ (first p1) (* (segment-d1 s) dx))
                               (+ (second p1) (* (segment-d1 s) dy))
                               (+ (first p1) (* (segment-d2 s) dx))
                               (+ (second p1) (* (segment-d2 s) dy))
                               (segment-type s)))
                     (line-segments l))))
              (set->list cp))))

(define (line-coord->cartesian s d)
  (case s
    [(0) (list d 0)]
    [(1) (list 1 d)]
    [(2) (list (- 1 d) 1)]
    [(3) (list 0 (- 1 d))]
    [else (raise "invalid coordinate")]))

(define (cp-line-on cp s1 d1 s2 d2)
  ;; get line between specified points if one exists, otherwise #f
  (let [[lines (apply append
                      (set-map cp (λ (l) (if (and (= s1 (line-s1 l)) (= d1 (line-d1 l))
                                                  (= s2 (line-s2 l)) (= d2 (line-d2 l)))
                                             (list l) '()))))]]
    (if (empty? lines) #f (first lines))))

(define (line-compose l1 l2 [result (list (segment 0 0 'U))])
  ;; takes two lists of segments to compose together
  (if (and (empty? l1) (empty? l2))
      (if (equal? (last result) (segment 0 0 'U))
          (rest (reverse result))
          (reverse result))
      (let* [[next-segment-l1? (cond [(empty? l1) #f]
                                     [(empty? l2) #t]
                                     [else
                                      (> (segment-d1 (first l1))
                                         (segment-d1 (first l2)))])]
            [next-segment (if next-segment-l1? (first l1) (first l2))]
            [next-result
             (cond
               [(> (segment-d1 next-segment) (segment-d2 (first result)))
                (cons next-segment result)]
               [(= (segment-d1 next-segment) (segment-d2 (first result)))
                (if (equal? (segment-type next-segment) (segment-type (first result)))
                    (cons (segment (segment-d1 (last result))
                                   (segment-d2 next-segment)
                                   (segment-type next-segment))
                          (rest result))
                    (cons next-segment result))]
               [else ;; <
                (if (equal? (segment-type next-segment) (segment-type (first result)))
                    (cons (segment (segment-d1 (first result))
                                   (max (segment-d2 (first result)) (segment-d2 next-segment))
                                   (segment-type next-segment))
                          (rest result))
                    #f)])]] ;; cannot compose, overlapping lines of different types
        (if next-result
            (line-compose (if next-segment-l1? (rest l1) l1)
                          (if next-segment-l1? l2 (rest l2))
                          next-result)
            #f))))

;;;;;;;;;;;;;;;
;; provisions
;;;;

(provide (struct-out line)
         (struct-out segment)
         cp->svg
         cp-compose
         cp-shared-lines
         cp->cartesian-segments)

;;;;;;;;;;;;
;; testing
;;;;

;(define waterbomb
;  (set (line 0 0 2 0 (list (segment 0 1 'M)))
;       (line 1 0 3 0 (list (segment 0 1 'M)))
;       (line 0 0.5 2 0.5 (list (segment 0 1 'V)))
;       (line 1 0.5 3 0.5 (list (segment 0 1 'V)))))

;(define D
;  (set (line 0 0.5 2 0.5 (list (segment 0 0.3 'V) (segment 0.7 1 'U)))
;       (line 0 0.5 1 0.5 (list (segment 0 1 'M)))
;       (line 1 0.5 2 0.5 (list (segment 0 1 'M)))))