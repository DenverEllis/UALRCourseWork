;; Work to read in from file later
(defvar *dataset* (list '(3.393533211, 2.331273381, 0)
			'(3.110073483, 1.781539638, 0)
			'(1.343808831, 3.368360954, 0)
			'(3.582294042, 4.67917911,  0)
			'(2.280362439, 2.866990263, 0)
			'(7.423436942, 4.696522875, 1)
			'(5.745051997, 3.533989803, 1)
			'(9.172168622, 2.511101045, 1)
			'(7.792783481, 3.424088941, 1)
			'(7.939820817, 0.791637231, 1)))

(defun sqr (x)
  (* x x))

(defun sum-l (list)
  (if (equal list nil) 0
      (+ (car x) (sum-l (cdr x)))))

(defun mean-l (list)
    "Average value"
    (if (equal list nil) 0
        (/ (sum-l list) (list-length list))))

(defun stdev-l (list)
  (sum-l

(defun separate-by-class (data)
