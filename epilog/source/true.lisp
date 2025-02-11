;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; true.lisp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-when (compile load eval)
  (proclaim '(special alist)))

(defmethod save (p th &optional (f 'samep))
 "(SAVE P TH &OPTIONAL (F 'SAMEP))
  SAVE takes as argument a sentence, a theory, and an equivalence
  checker.  If the theory contains a sentence that is equivalent (according
  to the specified equivalence checker), nothing happens, and SAVE returns NIL.
  Otherwise, the specified sentence is added to the end of the theory."
  (saveth p th f))

(defmethod drop (p th &optional (f 'samep))
 "(DROP P TH &OPTIONAL (F 'SAMEP))
  DROP takes as argument a sentence, a theory, and an equivalence
  checker.  It removes from the specified theory all sentences equivalent
  to the specified sentence (according to the specified equivalence 
  checker).  It returns T as value."
  (dropth p th f))

(defmethod drop* (p th &optional (f 'samep))
 "(DROP* P TH &OPTIONAL (F 'SAMEP))
  DROP takes as argument a sentence, a theory, and an equivalence
  checker.  It removes from the specified theory and all its included
  theories all sentences equivalent
  to the specified sentence (according to the specified equivalence 
  checker).  It returns T as value."
  (dropth* p th f))

(defmethod kill (p th &optional (f 'samep))
 "(KILL P TH &OPTIONAL (F 'SAMEP))
  KILL takes as argument an expression, a theory, and an equivalence
  checker.  It removes from the specified theory all sentences that 
  contain a subexpression equivalent to the specified expression (according 
  to the specified equivalence checker).  It returns T as value."
  (killth p th f))

(defmethod facts (x th &optional (f 'matchp))
 "(FACTS X TH &OPTIONAL (F 'MATCHP))
  FACTS takes as arguments an expression, a theory, an equivalence checker.
  It returns a list of all sentences in the specified theory that contain
  a subexpression equivalent to the specified expression (according to the 
  specified equivalence checker).  If no such sentences are found, it 
  returns NIL."
  (factsth x (indexps x th) f))

(defmethod facts (x (sents list) &optional (f 'matchp))
  (factsth x sents f))

(defmethod rules (x th &optional (f 'matchp))
 "(RULES X TH &OPTIONAL (F 'MATCHP))
  RULES takes as arguments an expression, a theory, an equivalence checker.
  It returns a list of all rules in the specified theory that contain
  a subexpression equivalent to the specified expression (according to the 
  specified equivalence checker).  If no such sentences are found, it 
  returns NIL."
  (rulesth x (indexps x th) f))

(defmethod rules (x (sents list) &optional (f 'matchp))
  (rulesth x sents f))

(defmethod sentences (x th &optional (f 'matchp))
 "(SENTENCES X TH &OPTIONAL (F 'MATCHP))
  SENTENCES takes as arguments an expression, a theory, an equivalence checker.
  It returns a list of all sentences in the specified theory and its included
  theories that contain a subexpression equivalent to the specified expression
  (according to the specified equivalence checker).  If no such sentences are
  found, it returns NIL."
  (nconc (facts x th f)
         (mapcan #'(lambda (th) (sentences x th f)) (includees th))))

(defmethod words (th)
 "(WORDS TH)
  WORDS takes a theory as argument and returns a list of all words contained
  is that theory's contents."
  (if (contents th) (getwords (contents th) nil)))

(defun getwords (x nl)
  (cond ((atom x) (if (not (varp x)) (adjoin x nl) nl))
        (t (do ((l x (cdr l)))
               ((null l) nl)
               (setq nl (getwords (car l) nl))))))


(defmethod truep (p th &optional (f 'matchp))
 "(TRUEP P TH &OPTIONAL (F 'MATCHP))
  TRUEP takes as argument a sentence, a theory, and an equivalence
  checker.  It returns T if there is an equivalent sentence in the 
  specified theory (according to the specified equivalence checker) and
  otherwise returns NIL."
  (truex t p th f))

(defmethod truex (x p th &optional (f 'matchp))
 "(TRUEX X P TH &OPTIONAL (F 'MATCHP))
  TRUEX takes as argument an expression, a sentence, a theory, and an
  equivalence checker.  It uses the equivalence checker to determine if there 
  is an equivalent sentence in the theory and, if so, returns a copy of
  the expression with variables replaced by values from the first successful
  equivalence check.  Otherwise, it returns NIL."
  (cond ((eq 'samep f) (truexsamep x p th))
        ((eq 'matchp f) (truexmatchp x p th))
        ((eq 'mgup f) (truexmgup x p th))
        ((eq 'unifyp f) (truexunifyp x p th))
        (t (truexother x p th f))))

(defun truexsamep (x p th)
  (do ((l (indexps p th) (cdr l)) (al))
      ((null l) nil)
      (if (setq al (samelist p (car l))) (return (plug x al)))))

(defun truexmatchp (x p th)
  (do ((l (indexps p th) (cdr l)) (al))
      ((null l) nil)
      (if (setq al (matcher p (car l))) (return (plug x al)))))

(defun truexmgup (x p th)
  (do ((l (indexps p th) (cdr l)) (al))
      ((null l) nil)
      (if (setq al (mgu p (car l))) (return (plug x al)))))

(defun truexunifyp (x p th)
  (do ((l (indexps p th) (cdr l)) (al (environment)) (bl (environment)))
      ((null l) nil)
      (let ((alist al))
        (if (unify p alist (car l) bl) (return (plugstdexp x alist))))))

(defun truexother (x p th f)
  (do ((l (indexps p th) (cdr l)))
      ((null l) nil)
      (if (funcall f p (car l)) (return x))))

(defmethod trues (x p th &optional (f 'matchp))
 "(TRUES X P TH &OPTIONAL (F 'MATCHP))
  TRUES takes as argument an expression, a sentence, a theory, and an
  equivalence checker.  It uses the equivalence checker to find all equivalent
  sentences in the theory and returns a list of copies of the specified
  expression with variables replaced by values from the successful equivalence
  checks.  It returns NIL if no equivalent expressions are found."
  (getall (truegth x p th f)))

(defmethod trueg (x p th &optional (f 'matchp))
 "(TRUEG X P TH &OPTIONAL (F 'MATCHP))
  TRUEG takes as arguments an expression, a sentence, a theory, and an optional 
  equivalence checker.  It returns a generator that uses the equivalence checker
  to determine if there is an equivalent sentence in the theory.  Each time the
  generator is called, it returns a copy of the expression with variables
  replaced by values from a successful equivalence check.  When all instances
  have been enumerated, the generator returns NIL."
  (truegth x p th f))


(defmethod knownp (p th &optional (f 'matchp))
 "(KNOWNP P TH &OPTIONAL (F 'MATCHP))
  KNOWNP takes as argument a sentence, a theory, and an equivalence
  checker.  It returns T if there is an equivalent sentence in the 
  specified theory or its included theories (according to the specified
  equivalence checker) and otherwise returns NIL."
  (funcall (knowngdb t p th f)))

(defmethod knownx (x p th &optional (f 'matchp))
 "(KNOWNX X P TH &OPTIONAL (F 'MATCHP))
  KNOWNX takes as argument an expression, a sentence, a theory, and an
  equivalence checker.  It uses the equivalence checker to determine if there 
  is an equivalent sentence in the theory or its included theories and, if so,
  returns a copy of the expression with variables replaced by values from the
  first successful equivalence check.  Otherwise, it returns NIL."
  (cond ((truex x p th f))
        (t (do ((l (includees th) (cdr l)) (dum))
               ((null l) nil)
               (when (setq dum (knownx x p (car l) f)) (return dum))))))

(defmethod knowns (x p th &optional (f 'matchp))
 "(KNOWNS X P TH &OPTIONAL (F 'MATCHP))
  KNOWNS takes as argument an expression, a sentence, a theory, and an
  equivalence checker.  It uses the equivalence checker to find all equivalent
  sentences in the theory and its included theories and returns a list of copies
  of the specified expression with variables replaced by values from the successful
  equivalence checks.  It returns NIL if no equivalent expressions are found."
  (getall (knowngdb x p th f)))

(defmethod knowng (x p th &optional (f 'matchp))
 "(KNOWNG X P TH &OPTIONAL (F 'MATCHP))
  KNOWNG takes as argument an expression, a sentence, a theory, and an
  equivalence checker and returns a generator as value.  On each call, the
  generator uses the specified equivalence checker to determine if there is an
  equivalent sentence in the theory or its included theories and, if so,
  returns a copy of the expression with variables replaced by values from the
  first successful equivalence check.  When all such instances have been
  enumerated, the generator returns NIL."
  (knowngdb x p th f))

(defun knowngdb (x p th f)
  (let ((cont (trueg x p th f)) (flag) (ths))
    #'(lambda ()
        (do ((ans))
            ((setq ans (funcall cont)) (return ans))
            (cond ((and (not flag) (setq flag t ths (includees th)) nil))
                  ((null ths) (return nil))
                  (t (setq cont (knowngdb x p (car ths) f) ths (cdr ths))))))))

(defmethod setval (x y th &optional (f 'samep))
 "(SETVAL X Y TH &OPTIONAL (F 'SAMEP))
  SETVAL takes an expression <x>, and expression <y>, a theory, and a matcher
  as arguments.  It deletes from the specified theory all sentences of the
  form (= <u> <v>), where <u> is equivalent to <x> according to the specified
  matcher, and then saves (= <x> <y>).  SETVAL returns <y> as value."
  (remvalth x th f)
  (insert `(= ,x ,y) th)
  y)

(defmethod remval (x th &optional (f 'samep))
 "(REMVAL X TH &OPTIONAL (F 'SAMEP))
  REMVAL takes an expression <x>, a theory, and a matcher as arguments.  It 
  deletes from the specified theory all sentences of the form (= <u> <v>),
  where <u> is equivalent to <x> according to the specified matcher.  REMVAL
  returns T as value."
  (remvalth x th f))

(defmethod getval (x th &optional (f 'matchp))
 "(GETVAL X TH &OPTIONAL (F 'MATCHP))
  GETVAL takes an expression <x>, a theory, and a matcher as arguments.  It
  examines the specified theory for a sentence of the form (= <u> <v>), where
  <u> is equivalent to <x> according to the specified matcher.  If it finds one,
  it returns an appropriate instance of <v>.  Otherwise, it returns NIL."
  (getvalth x th f))

(defmethod value (x th &optional (f 'matchp))
 "(VALUE X TH &OPTIONAL (F 'MATCHP))
  VALUE takes an expression, a theory, and a matcher as arguments.  It uses
  GETVAL on the  specified theory and its included theories until it finds a
  value.  If no value is found, VALUE returns NIL."
  (valuedb x th f))

(defun valuedb (x th f)
  (cond ((getval x th f))
        (t (do ((l (includees th) (cdr l)) (ans))
               ((null l) nil)
               (if (setq ans (valuedb x (car l) f)) (return ans))))))


(defun saveth (p th f)
  (do ((l (indexps p th) (cdr l)))
      ((null l) (insert p th))
      (if (funcall f p (car l)) (return nil))))

;;; Note that DROPTH drops all sentences equivalent to P.  This
;;; is more expensive than it need be if facts are added with the
;;; same equivalence checker used for removal.  But it is nice this way.

(defun dropth* (p th f)
  (mapc #'(lambda (x) (dropth* p x f)) (includees th))
  (dropth p th f))

(defun dropth (p th f)
  (do ((l (indexps p th) (cdr l)))
      ((null l) t)
      (if (funcall f p (car l)) (uninsert (car l) th))))

(defun killth (x th f)
  (do ((l (indexps x th) (cdr l)))
      ((null l) t)
      (if (partp x (car l) f) (uninsert (car l) th))))

(defun factsth (x sents f)
  (do ((l sents (cdr l)) (nl))
      ((null l) (nreverse nl))
      (if (partp x (car l) f) (setq  nl (cons (car l) nl)))))

(defun rulesth (x sents f)
  (do ((l sents (cdr l)) (nl))
      ((null l) (nreverse nl))
      (when (and (listp (car l)) (eq (caar l) '<=) (partp x (car l) f))
        (setq  nl (cons (car l) nl)))))

(defun truegth (x p th f)
  (cond ((eq 'samep f) (truegsamep x p th))
        ((eq 'matchp f) (truegmatchp x p th))
        ((eq 'mgup f) (truegmgup x p th))
        ((eq 'unifyp f) (truegunifyp x p th))
        (t (truegother x p th f))))

(defun truegsamep (x p th)
  (let ((l (indexps p th)))
    #'(lambda ()
        (do ((q) (al))
            ((null l) nil)
            (setq q (car l) l (cdr l))
            (if (setq al (samelist p q)) (return (plug x al)))))))

(defun truegmatchp (x p th)
  (let ((l (indexps p th)))
    #'(lambda ()
        (do ((q) (al))
            ((null l) nil)
            (setq q (car l) l (cdr l))
            (if (setq al (matcher p q)) (return (plug x al)))))))

(defun truegmgup (x p th)
  (let ((l (indexps p th)))
    #'(lambda ()
        (do ((q) (al))
            ((null l) nil)
            (setq q (car l) l (cdr l))
            (if (setq al (mgu p q)) (return (plug x al)))))))

(defun truegunifyp (x p th)
  (let ((l (indexps p th)) (al (environment)) (bl (environment)))
    #'(lambda ()
        (do ((q) (alist al))
            ((null l) nil)
            (setq q (car l) l (cdr l))
            (if (unify p alist q bl) (return (plugstdexp x alist)))))))

(defun truegother (x p th f)
  (let ((l (indexps p th)))
    #'(lambda ()
        (do ((q))
            ((null l) nil)
            (setq q (car l) l (cdr l))
            (if (funcall f p q) (return x))))))

(defun remvalth (x th f)
  (do ((l (indexps x th) (cdr l)))
      ((null l) t)
      (if (and (listp (car l)) (eq '= (caar l)) (funcall f x (cadar l)))
          (uninsert (car l) th))))

(defun getvalth (x th f)
  (cond ((eq 'samep f) (getvalsamep x th))
        ((eq 'instp f) (getvalinstp x th))
        ((eq 'mgup f) (getvalmgup x th))
        ((eq 'unifyp f) (getvalunifyp x th))
        (t (getvalother x th f))))

(defun getvalsamep (x th)
  (do ((l (indexps x th) (cdr l)) (al))
      ((null l) nil)
      (if (and (listp (car l)) (eq '= (caar l))
               (setq al (samelist (cadar l) x)))
          (return (plug (caddar l) al)))))

(defun getvalinstp (x th)
  (do ((l (indexps x th) (cdr l)) (al))
      ((null l) nil)
      (if (and (listp (car l)) (eq '= (caar l))
               (setq al (instantiator x (cadar l))))
          (return (plug (caddar l) al)))))

(defun getvalmgup (x th)
  (do ((l (indexps x th) (cdr l)) (al))
      ((null l) nil)
      (if (and (listp (car l)) (eq '= (caar l))
               (setq al (mgu x (cadar l))))
          (return (plug (caddar l) al)))))

(defun getvalunifyp (x th)
  (do ((l (indexps x th) (cdr l)) (al (environment)) (alist (environment)) (ol))
      ((null l) nil)
      (if (and (listp (car l)) (eq '= (caar l))
               (setq ol (unify x al (cadar l) alist)))
          (return (prog1 (plugstdexp (caddar l) alist) (backup ol))))))

(defun getvalother (x th f)
  (do ((l (indexps x th) (cdr l)))
      ((null l) nil)
      (if (and (listp (car l)) (eq '= (caar l))
               (funcall f x (cadar l))) 
          (return (caddar l)))))

;;; Yes, the quote case is expensive.
;;; Should fix some day.

(defun partp (x y f)
  (cond ((funcall f x y))
        ((atom y) nil)
        ((eq 'quote (car y))
         (cond ((atom (cadr y)) nil)
               (t (partp x (cons 'list (mapcar 'quotify (cadr y))) f))))
        (t (some #'(lambda (z) (partp x z f)) y))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
