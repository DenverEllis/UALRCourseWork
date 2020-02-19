;; Note: To scale this to a 3rd or nth dimension, only the distance function
;;       needs to be modified

;; Take in arguments, will be used later
(defparameter *target* (cadr *args*))
(defparameter *pop-size* (parse-integer (car *args*)))

;; Set globals for mutation and cross-over rate. Allows for easy comparison
;; of results
(defvar *mutation-rate* 0.001)
(defvar *crossover-rate* 0.7)

;; I Intend to change this to read a list of cities from a file later
(defparameter *cities* (list
			'(A 6734 1453)
			'(B 2233 10)
			'(C 5530 1424)
			'(D 401 841)
			'(E 3082 1644)
			'(F 7608 4458)
			'(G 7573 3716)
			'(H 7265 1268)
			'(I 6898 1885)
			'(J 1112 2049)
			'(K 5468 2606)
			'(L 5989 2873)
			'(M 4706 2674)
			'(N 4612 2035)
			'(O 6347 2683)
			'(P 6107 669)
			'(Q 7611 5184)
			'(R 7462 3590)
			'(S 7732 4723)
			'(T 5900 3561)
			'(U 4483 3369)
			'(V 6101 1110)
			'(W 5199 2182)
			'(X 1633 2809)
			'(Y 4307 2322)
			'(Z 675 1006)
			'(AA 7555 4819)
			'(AB 7541 3981)
			'(AC 3177 756)
			'(AD 7352 4506)
			'(AE 7545 2801)
			'(AF 3245 3305)
			'(AG 6426 3173)
			'(AH 4608 1198)
			'(AI 23 2216)
			'(AJ 7248 3779)
			'(AK 7762 4595)
			'(AL 7392 2244)
			'(AM 3484 2829)
			'(AN 6271 2135)
			'(AO 4985 140)
			'(AP 1916 1569)
			'(AQ 7280 4899)
			'(AR 7509 3239)
			'(AS 10 2676)
			'(AT 6807 2993)
			'(AU 5185 3258)
			'(AV 3023 1942)))

;;Helper function to square a number
(defun sqr (x)
  (* x x))

;; Helper function to sort rankings from Hi to Lo
(defun selection-sort (list)
  (when list
    (let ((maximum-element (reduce #'max list)))
      (cons maximum-element
            (selection-sort (remove maximum-element list))))))

(defun random-item (chromosome)
  "Take a list and return one random item"
  (nth (random (length chromosome)) chromosome))

(defun generate-random-chromosome (chromosome)
  "Make a chromosome from the list at random. To do this, copy list and shuffle"
  (loop for i from (length chromosome) downto 2
        do (rotatef (elt chromosome (random i))
                    (elt chromosome (1- i))))
  chromosome)

(defun distance (x1 y1 x2 y2)
  "Find the distance between two cities"
  (sqrt (+ (sqr (- x2 x1)) (sqr (- y2 y1)))))

(defun route-distance (chromosome)
  "Find the total distance travelled on a route. This is also the fitness"
  (if (not (null (cdr chromosome)))
      (+ (distance (cadar chromosome)
		   (caddar chromosome)
		   (cadadr chromosome)
		   (car (cddadr chromosome)))
	 (route-distance (cdr chromosome)))
     (cadar chromosome)))

(defun mutate-gene (gene chromosome)
  "Mutate a gene by swapping the positions of a random city with another random city"
  (if (< (random 1.0) *mutation-rate*)
      (rotatef gene (random-item chromosome))
      gene))

(defun mutate (chromosome)
  "Have a chance to mutate every gene in a chromosome"
  (loop for gene in chromosome
     collect (mutate-gene gene chromosome)))

(defun pool-fitness (pool)
  "Return the route distance for each chromosome"
  (loop for chromosome in pool
       collect (route-distance chromosome)))

(defun crossover (first second)
  "Returns a mix of two chromosomes. No change is a valid possibility"
  (if (< (random 1.0) *crossover-rate*)
      (let ((point (+ (random (- (length first) 1)) 1)))
	(append (subseq first 0 point)
		(subseq second point)))
    (random-item (list first second))))

(defun encode-gene (chromosome gene)
  "Helper function for crossover"
  (list (position gene chromosome :key #'car :test #'eql)
        (remove gene chromosome :key #'car :test #'eql)))
;; when city names are strings use `:test #'string=
;; (0 2 2 0 0)

(defun encode-chromosome (city-list city-sequence)
  "Helper function for crossover"
  (let ((current-cities city-list))
    (loop for current-city in city-sequence
          for (idx updated-cities) = (encode-gene current-cities current-city)
          collect (progn (setf current-cities updated-cities)
                         idx)
            into index-positions
          finally (return index-positions))))

;; a tail-call recursive version:
(defun encode-chromosome (cities city-sequence
                                   &key (acc-cities '())
                                        (acc-positions '())
                                        (pos-counter 0)
                                        (test #'eql))
  "Helper function for crossover"
    (cond ((or (null city-sequence) (null cities)) (nreverse acc-positions))
          ((funcall test (car city-sequence) (car cities))
           (encode-chromosome (append (nreverse acc-cities) (cdr cities))
			      (cdr city-sequence)
			      :acc-cities '()
			      :acc-positions (cons pos-counter acc-positions)
			      :pos-counter 0
			      :test test))
          (t (encode-chromosome (cdr cities)
				city-sequence
				:acc-cities (cons (car cities) acc-cities)
				:acc-positions acc-positions
				:pos-counter (1+ pos-counter)
				:test test))))

(defun decode-gene (chromosome gene)
  "Helper to decode after crossover"
  (list (position gene chromosome :key #'car :test #'eql)
	(remove gene chromosome :key #'car :test #'eql)))

(defun decode-chromosome (chromosome city-sequence)
  (let ((current-cities city-list))
    (loop for current-city in city-sequence
       for (idx updated-cities) = (decode-gene current-cities current-city)
       collect (progn (setf current-cities updated-cities)
		      idx)
       into index-positions
       finally (return index-positions))))

(defun make-probability (fitness)
  (let ((total-fitness (reduce #'+ fitness))
	(total-probability 0.0))
    (append (loop for chromosome in fitness
	       collect total-probability
	       do (incf total-probability (/ chromosome total-fitness))) '(1.0))))

(defun assert-probability (pool probability-chart)
  (let ((picked (random 1.0)))
    (declare (type float picked))
    (loop for chromosome in pool
       for (position next-pos) of-type (float float) on probability-chart
       if (<= picked next-pos)
       do (return chromosome))))

(defun repopulate (pool fitness)
  (let ((probability-chart (make-probability fitness)))
    (loop for i from 1 to (length pool)
	  collect (mutate (crossover (encode-chromosome
				      (copy-list (assert-probability pool probability-chart))
				      (copy-list *cities*))
				     (encode-chromosome
				      (copy-list (assert-probability pool probability-chart))
				      (copy-list *cities*)))))))

(defun create-initial-pool (pool-size chromosome)
  (loop for i from 1 to pool-size
     collect (generate-random-chromosome chromosome)))

(defun find-best-chromosome (pool fitness)
  "Returns the most fit chromosome in the pool"
  (let ((best-score) (best-chromosome))
    (loop for chromosome in pool
       for score in fitness
       do (when (or (equalp score 0) (not best-score) (> score best-score))
	    (setf best-score score)
	    (setf best-chromosome chromosome)))
    (values best-chromosome best-score)))

(defun display-turn (pool fitness turn)
  (multiple-value-bind (chromosome score) (find-best-chromosome pool fitness)
    (let ((avg-fitness (/ (reduce #'+ fitness) (+ 1 (length pool))))
	  (*print-pretty* nil))
      (format t "~a - Average Fitness: ~F Best: ~w (fitness ~F)~%" turn avg-fitness chromosome score))))

(defun genetic-algorithm (pop-size chromosome tries)
  "Pass in the initial list of cities as the chromosome"
  (let ((pool (create-initial-pool pop-size chromosome))
	(fitness))
    (loop for i from 1 to tries
       do (setf fitness (pool-fitness pool))
       do (display-turn pool fitness i)
       do (setf pool (repopulate pool fitness))
       finally (return (find-best-chromosome pool fitness)))))


;(genetic-algorithm 5 (copy-list *cities*) 10)




;;; ========================================================================================
;;; The below commands were called for debugging. Use it for insight into my thought process
;;; ========================================================================================

;(format t (write-to-string (generate-random-chromosome (copy-list *cities*))))
;(format t (write-to-string (generate-random-chromosome (copy-list *cities*))))
;(format t (write-to-string (random-item *cities*)))
;(format t (write-to-string *cities*))
;(format t (write-to-string (cdar *cities*)))
;(format t (write-to-string (cdadr *cities*)))
;(format t (write-to-string (distance 0 3 4 0)))
;(format t (write-to-string (car (cddadr *cities*))))

;(format t (write-to-string (distance (cadar *cities*)
;				     (caddar *cities*)
;				     (cadadr *cities*)
;				     (car (cddadr *cities*)))))

;(format t (write-to-string *cities*))
;(format t (write-to-string (car (cddadr *cities*))))


;(format t (write-to-string (route-distance *cities*)))
;(terpri)
;(format t (write-to-string (route-distance (generate-random-chromosome (copy-list *cities*)))))
;(terpri)
;(format t (write-to-string (route-distance (mutate (generate-random-chromosome (copy-list *cities*))))))

;(defvar *pool* (list *cities*
;		     (generate-random-chromosome (copy-list *cities*))
;		     (generate-random-chromosome (copy-list *cities*))
;		     (generate-random-chromosome (copy-list *cities*))
;		     (generate-random-chromosome (copy-list *cities*))))

;(format t (write-to-string (pool-fitness *pool*)))
;(format t (write-to-string (choose-cities-subsequently (generate-random-chromosome (copy-list *cities*)) *cities*)))

;(loop for city in *pool*
;      do (format t (write-to-string (choose-cities-subsequently city *cities*))))


;(format t (write-to-string (repopulate *pool* (pool-fitness *pool*))))
(format t (write-to-string (decode-gene (encode-chromosome (copy-list (generate-random-chromosome (copy-list *cities*))) *cities*) *cities*)))
