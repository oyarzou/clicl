;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; (c) Copyright 1999-2005 by Michael Genesereth.  All rights reserved.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; database.lisp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-when (compile load eval)
  (proclaim '(special *thing* *answers* *sentences* *theory*)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; fastfindp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun fastfindp (p th)
  (fastfindx t p th))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; fastfindx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun fastfindx (*thing* p *theory*)
  (let ((al))
    (setq p (order *thing* p))
    (when (setq al (findone (adjust *thing* p) truth nil))
      (plug *thing* al))))

(defun fancyindexp (x th)
  (some #'(lambda (sub) (indexees x sub)) (includees th)))

(defun findone (p al pl)
  (cond ((atom p) (findoneconstant p al pl))
        ((eq (car p) 'not) (findonenot (cadr p) al pl))
        ((eq (car p) 'and) (findoneand p al pl))
        ((eq (car p) 'or) (findoneor p al pl))
        ((eq (car p) 'same) (findonesame p al pl))
        ((eq (car p) 'distinct) (findonedistinct p al pl))
        ((eq (car p) 'oneof) (findoneoneof p al pl))
        ((eq (car p) 'choose) (findonechoose p al pl))
        ((eq (car p) 'bagofall) (findonebagofall p al pl))
        ((eq (car p) 'unprovable) (findoneunprovable p al pl))
	((eq (car p) 'ground) (findoneground p al pl))
	((eq (car p) 'nonground) (findonenonground p al pl))
        ((eq (car p) 'execute) (findoneexecute p al pl))
        ((eq (car p) 'evaluate) (findoneevaluate p al pl))
        ((eq (car p) 'stringmatch) (findonestrmatch p al pl))
	((get (car p) 'basicval) (findonebasicvalue p al pl))
        ((get (car p) 'basic) (findonebasic p al pl))
        (t (findoners p al pl))))

(defun findonenot (p al pl)
  (cond ((atom p) (findonenotconstant p al pl))
        ((eq (car p) 'not) (findone (cadr p) al pl))
        ((eq (car p) 'and) (findonenotand p al pl))
        ((eq (car p) 'or) (findonenotor p al pl))
        ((eq (car p) 'same) nil)
        ((eq (car p) 'distinct) nil)
        ((eq (car p) 'oneof) (findonenotoneof p al pl))
        ((eq (car p) 'choose) (findonenotchoose p al pl))
        ((eq (car p) 'bagofall) (findonenotbagofall p al pl))
        ((eq (car p) 'unprovable) (findone (cadr p) al pl))
	((eq (car p) 'ground) nil)
	((eq (car p) 'nonground) nil)
        ((eq (car p) 'execute) (findonenotexecute p al pl))
        ((eq (car p) 'evaluate) (findonenotevaluate p al pl))
        ((eq (car p) 'stringmatch) (findonenotstrmatch p al pl))
	((get (car p) 'basicval) (findonenotbasicvalue p al pl))
        ((get (car p) 'basic) (findonenotbasic p al pl))
        (t (findoneunprovable `(not ,p) al pl))))

(defun findoneconstant (p al pl)
  (cond ((eq 'true p) (finddone al pl))
        ((eq 'false p) nil)
        (t (findoners p al pl))))

(defun findonenotconstant (p al pl)
  (cond ((eq 'true p) nil)
        ((eq 'false p) (finddone al pl))
        (t (findoners `(not ,p) al pl))))

(defun findoneand (p al pl)
  (cond ((null (cdr p)) (finddone al pl))
        (t (findone (cadr p) al (append (cddr p) pl)))))

(defun findonenotand (p al pl)
  (do ((l (cdr p) (cdr l)) (bl))
      ((null l) nil)
      (if (setq bl (findonenot (car l) al pl)) (return bl))))

(defun findoneor (p al pl)
  (do ((l (cdr p) (cdr l)) (bl))
      ((null l) nil)
      (if (setq bl (findone (car l) al pl)) (return bl))))

(defun findonenotor (p al pl)
  (cond ((null (cdr p)) (finddone al pl))
        (t (findonenot (cadr p) al (append (mapcar #'maknot (cddr p)) pl)))))

(defun findonesame (p al pl)
  (if (setq al (mgwexp (cadr p) (caddr p) al)) (finddone al pl)))

(defun findonedistinct (p al pl)
  (if (mgwexp (cadr p) (caddr p) al) nil (finddone al pl)))

(defun findoneoneof (p al pl)
  (when (seqvarp (caddr p)) (setq p (plug p al)))
  (do ((l (cddr p) (cdr l)) (bl))
      ((null l) nil)
      (if (and (setq bl (mgwexp (cadr p) (car l) al))
               (setq bl (finddone bl pl)))
          (return bl))))

(defun findonenotoneof (p al pl)
  (when (seqvarp (caddr p)) (setq p (plug p al)))
  (do ((l (cddr p) (cdr l)))
      ((null l) (finddone al pl))
      (when (mgwexp (cadr p) (car l) al) (return nil))))

(defun findonechoose (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (fastfindx (cadr p) (caddr p) *theory*))
    (when (and answer (setq al (mgwexp (cadddr p) answer al))) (finddone al pl))))

(defun findonenotchoose (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (fastfindx (cadr p) (caddr p) *theory*))
    (unless (and answer (mgwexp (cadddr p) answer al)) (finddone al pl))))

(defun findonebagofall (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (cons 'listof (finds (cadr p) (caddr p) *theory*)))
    (when (setq al (mgwexp (cadddr p) answer al)) (finddone al pl))))

(defun findonenotbagofall (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (cons 'listof (finds (cadr p) (caddr p) *theory*)))
    (unless (mgwexp (cadddr p) answer al) (finddone al pl))))

(defun findoneunprovable (p al pl)
  (setq p (deskolemize p))
  (cond ((findone (cadr p) al pl) nil)
        (t (finddone al pl))))

(defun deskolemize (x)
  (let (alist)
    (deskolemizesentence x)))

(defun deskolemizesentence (x)
  (cond ((atom x) x)
        ((find (car x) '(not and or)) (mapcar #'deskolemizesentence x))
        (t (cons (car x) (mapcar #'deskolemizeterm (cdr x))))))

(defun deskolemizeterm (x)
  (let (dum)
    (cond ((atom x) x)
          ((setq dum (assoc x alist :test #'eq)) (cdr dum))
          (t (setq alist (acons x (newindvar) alist))
             (cdar alist)))))

(defun findoneground (p al pl)
  (setq p (plug p al))
  (if (groundp p) (finddone al pl)))

(defun findonenonground (p al pl)
  (setq p (plug p al))
  (if (groundp p) nil (finddone al pl)))

(defun findoneexecute (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p)) (if (ignore-errors (eval (cadr p))) (finddone al pl)))
          ((and (car (setq values (ignore-errors (multiple-value-list (eval (cadr p))))))
                (setq al (matchpexp (cddr p) (mapcar #'quotify values) al)))
           (finddone al pl)))))

(defun findonenotexecute (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p))
           (if (ignore-errors (not (eval (cadr p)))) (finddone al pl)))
          ((and (car (setq values (ignore-errors (multiple-value-list (eval (cadr p))))))
                (not (matchpexp (cddr p) (mapcar #'quotify values) al)))
           (finddone al pl)))))

(defun findoneevaluate (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p)) (if (evals (cadr p)) (finddone al pl)))
          ((and (car (setq values (evals (cadr p))))
                (setq al (matchpexp (cddr p) values al)))
           (finddone al pl)))))

(defun findonenotevaluate (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p))
           (if (ignore-errors (not (apply (caadr p) (cdadr p)))) (finddone al pl)))
          ((and (car (setq values (ignore-errors (multiple-value-list (apply (caadr p) (cdadr p))))))
                (not (matchpexp (cddr p) values al)))
           (finddone al pl)))))

(defun findonestrmatch (p al pl)
  (findone `(execute (strmatches ,(cadr p) ,(caddr p)) ? . ,(cdddr p)) al pl))

(defun findonenotstrmatch (p al pl)
  (findonenot `(execute (strmatches ,(cadr p) ,(caddr p)) ? . ,(cdddr p)) al pl))

(defun findonebasicvalue (p al pl)
  (let (x y)
    (setq p (plug p al) x (butlast p) y (car (last p)))
    (if (and (groundp x) (every #'primitivep (cdr x))
             (setq x (funcall (get (car x) 'basicval) x))
             (setq al (mgwexp x y al)))
        (finddone al pl))))

(defun findonenotbasicvalue (p al pl)
  (let (x y)
    (setq p (plug p al) x (butlast p) y (car (last p)))
    (if (and (groundp x) (every #'primitivep (cdr x))
             (setq x (funcall (get (car x) 'basicval) x))
             (not (mgwexp x y al)))
        (finddone al pl))))

(defun findonebasic (p al pl)
  (setq p (plug p al))
  (if (and (groundp p) (apply (get (car p) 'basic) (cdr p))) (finddone al pl)))

(defun findonenotbasic (p al pl)
  (setq p (plug p al))
  (if (and (groundp p) (not (apply (get (car p) 'basic) (cdr p))))
      (finddone al pl)))

(defun findknownrs (p al pl)
  (findknowndb p al pl *theory*))

(defun findknowndb (p al pl th)
  (cond ((findknownth p al pl th))
        (t (do ((l (includees th) (cdr l)) (bl))
               ((null l))
               (if (setq bl (findknowndb p al pl (car l))) (return bl))))))

(defun findknownth (p al pl th)
  (do ((l (envindexps p al th) (cdr l)) (bl truth))
      ((null l) nil)
      (if (and (setq bl (matchpexp p (car l) al)) (setq bl (finddone bl pl)))
          (return bl))))

(defun findoners (p al pl)
  (findonedb p al pl *theory*))

(defun findonedb (p al pl th)
  (cond ((findoneth p al pl th))
        (t (do ((l (includees th) (cdr l)) (bl))
               ((null l))
               (if (setq bl (findonedb p al pl (car l))) (return bl))))))

(defun findoneth (p al pl th)
  (do ((l (envindexps p al th) (cdr l)) (bl truth))
      ((null l) nil)
      (cond ((and (listp (car l)) (eq '<= (caar l))
                  (setq bl (matcher (cadar l) p))
                  (setq bl (findone (plugstd (maksand (cddar l)) bl) al pl)))
             (return bl))
            ((and (setq bl (matchpexp p (car l) al)) (setq bl (finddone bl pl)))
             (return bl)))))

(defun finddone (al pl)
  (cond ((null pl) al)
        (t (findone (car pl) al (cdr pl)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; fastfinds
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun fastfinds (*thing* p *theory*)
  (let (*answers*)
    (setq p (order *thing* p))
    (findall (adjust *thing* p) truth nil) 
    (nreverse (uniquify *answers*))))

(defun findall (p al pl)
  (cond ((atom p) (findallconstant p al pl))
        ((eq (car p) 'not) (findallnot (cadr p) al pl))
        ((eq (car p) 'and) (findalland p al pl))
        ((eq (car p) 'or) (findallor p al pl))
        ((eq (car p) 'same) (findallsame p al pl))
        ((eq (car p) 'distinct) (findalldistinct p al pl))
        ((eq (car p) 'oneof) (findalloneof p al pl))
        ((eq (car p) 'choose) (findallchoose p al pl))
        ((eq (car p) 'bagofall) (findallbagofall p al pl))
        ((eq (car p) 'unprovable) (findallunprovable p al pl))
	((eq (car p) 'ground) (findallground p al pl))
	((eq (car p) 'nonground) (findallnonground p al pl))
        ((eq (car p) 'execute) (findallexecute p al pl))
        ((eq (car p) 'evaluate) (findallevaluate p al pl))
        ((eq (car p) 'stringmatch) (findallstrmatch p al pl))
	((get (car p) 'basicval) (findallbasicvalue p al pl))
        ((get (car p) 'basic) (findallbasic p al pl))
        (t (findallrs p al pl))))

(defun findallnot (p al pl)
  (cond ((atom p) (findallnotconstant p al pl))
        ((eq (car p) 'not) (findall (cadr p) al pl))
        ((eq (car p) 'and) (findallnotand p al pl))
        ((eq (car p) 'or) (findallnotor p al pl))
        ((eq (car p) 'same) nil)
        ((eq (car p) 'distinct) nil)
        ((eq (car p) 'oneof) (findallnotoneof p al pl))
        ((eq (car p) 'choose) (findallnotchoose p al pl))
        ((eq (car p) 'bagofall) (findallnotbagofall p al pl))
        ((eq (car p) 'unprovable) (findall (cadr p) al pl))
	((eq (car p) 'ground) nil)
	((eq (car p) 'nonground) nil)
        ((eq (car p) 'execute) (findallnotexecute p al pl))
        ((eq (car p) 'evaluate) (findallnotevaluate p al pl))
        ((eq (car p) 'stringmatch) (findallnotstrmatch p al pl))
	((get (car p) 'basicval) (findallnotbasicvalue p al pl))
        ((get (car p) 'basic) (findallnotbasic p al pl))
        (t (findallunprovable `(not ,p) al pl))))

(defun findallconstant (p al pl)
  (cond ((eq p 'true) (findexit al pl))
        ((eq p 'false) nil)
        (t (findallrs p al pl))))

(defun findallnotconstant (p al pl)
  (cond ((eq p 'true) nil)
        ((eq p 'false) (findexit al pl))
        (t (findallrs `(not ,p) al pl))))

(defun findalland (p al pl)
  (cond ((null (cdr p)) (findexit al pl))
        (t (findall (cadr p) al (append (cddr p) pl)))))

(defun findallnotand (p al pl)
  (do ((l (cdr p) (cdr l)))
      ((null l))
      (findallnot (car l) al pl)))

(defun findallor (p al pl)
  (do ((l (cdr p) (cdr l)))
      ((null l))
      (findall (car l) al pl)))

(defun findallnotor (p al pl)
  (cond ((null (cdr p)) (findexit al pl))
        (t (findallnot (cadr p) al (append (mapcar #'maknot (cddr p)) pl)))))

(defun findallsame (p al pl)
  (if (setq al (mgwexp (cadr p) (caddr p) al)) (findexit al pl)))

(defun findalldistinct (p al pl)
  (if (mgwexp (cadr p) (caddr p) al) nil (findexit al pl)))

(defun findalloneof (p al pl)
  (when (seqvarp (caddr p)) (setq p (plug p al)))
  (do ((l (cddr p) (cdr l)) (bl))
      ((null l) t)
      (if (setq bl (mgwexp (cadr p) (car l) al))
          (findexit bl pl))))

(defun findallnotoneof (p al pl)
  (when (seqvarp (caddr p)) (setq p (plug p al)))
  (do ((l (cddr p) (cdr l)))
      ((null l) (findexit al pl))
      (when (mgwexp (cadr p) (car l) al) (return nil))))

(defun findallchoose (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (fastfindx (cadr p) (caddr p) *theory*))
    (when (and answer (setq al (mgwexp (cadr p) answer al))) (findexit al pl))))

(defun findallnotchoose (p al pl)
  (setq p (plug p al))
  (cond ((fastfindp (caddr p) *theory*) nil)
        (t (findexit al pl))))

(defun findallbagofall (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (cons 'listof (finds (cadr p) (caddr p) *theory*)))
    (when (setq al (mgwexp (cadddr p) answer al)) (findexit al pl))))

(defun findallnotbagofall (p al pl)
  (let (answer)
    (setq p (plug p al))
    (setq answer (cons 'listof (finds (cadr p) (caddr p) *theory*)))
    (unless (mgwexp (cadddr p) answer al) (findexit al pl))))

(defun findallunprovable (p al pl)
  (setq p (deskolemize p))
  (cond ((findone (cadr p) al pl) nil)
        (t (findexit al pl))))

(defun findallground (p al pl)
  (setq p (plug p al))
  (if (groundp p) (findexit al pl)))

(defun findallnonground (p al pl)
  (setq p (plug p al))
  (if (groundp p) nil (findexit al pl)))

(defun findallexecute (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p))
           (if (ignore-errors (eval (cadr p))) (findexit al pl)))
          ((and (car (setq values (ignore-errors (multiple-value-list (eval (cadr p))))))
                (setq al (matchpexp (cddr p) (mapcar #'quotify values) al)))
           (findexit al pl)))))
    
(defun findallnotexecute (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p))
           (if (ignore-errors (not (eval (cadr p)))) (findexit al pl)))
          ((and (car (setq values (evals (cadr p))))
                (not (matchpexp (cddr p) (mapcar #'quotify values) al)))
           (findexit al pl)))))

(defun findallevaluate (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p))
           (if (ignore-errors (apply (caadr p) (cdadr p))) (findexit al pl)))
          ((and (car (setq values (evals (cadr p))))
                (setq al (matchpexp (cddr p) values al)))
           (findexit al pl)))))
    
(defun findallnotevaluate (p al pl)
  (let (values)
    (setq p (plug p al))
    (cond ((null (cddr p))
           (if (ignore-errors (not (apply (caadr p) (cdadr p)))) (findexit al pl)))
          ((and (car (setq values (ignore-errors (multiple-value-list (apply (caadr p) (cdadr p))))))
                (not (matchpexp (cddr p) values al)))
           (findexit al pl)))))

(defun findallstrmatch (p al pl)
  (findall `(execute (strmatches ,(cadr p) ,(caddr p)) ? . ,(cdddr p)) al pl))

(defun findallnotstrmatch (p al pl)
  (findallnot `(execute (strmatches ,(cadr p) ,(caddr p)) ? . ,(cdddr p)) al pl))

(defun findallbasicvalue (p al pl)
  (let (x y)
    (setq p (plug p al) x (butlast p) y (car (last p)))
    (if (and (groundp x) (every #'primitivep (cdr x))
             (setq x (funcall (get (car x) 'basicval) x))
             (setq al (mgwexp x y al)))
        (findexit al pl))))

(defun findallnotbasicvalue (p al pl)
  (let (x y)
    (setq p (plug p al) x (butlast p) y (car (last p)))
    (if (and (groundp x) (every #'primitivep (cdr x))
             (setq x (funcall (get (car x) 'basicval) x))
             (not (mgwexp x y al)))
        (findexit al pl))))

(defun findallbasic (p al pl)
  (setq p (plug p al))
  (if (and (groundp p) (apply (get (car p) 'basic) (cdr p))) (findexit al pl)))

(defun findallnotbasic (p al pl)
  (setq p (plug p al))
  (if (and (groundp p) (not (apply (get (car p) 'basic) (cdr p))))
      (findexit al pl)))

(defun findallrs (p al pl)
  (findalldb p al pl *theory*))

(defun findalldb (p al pl th)
  (findallth p al pl th)
  (do ((l (includees th) (cdr l)))
      ((null l))
      (findalldb p al pl (car l))))

(defun findallth (p al pl th)
  (do ((l (envindexps p al th) (cdr l)) (bl truth))
      ((null l) nil)
      (cond ((and (listp (car l)) (eq '<= (caar l))
                  (setq bl (matcher (cadar l) p)))
             (findall (plugstd (maksand (cddar l)) bl) al pl))
            ((setq bl (matchpexp p (car l) al)) (findexit bl pl)))))

(defun findexit (al pl)
  (cond ((null pl)
         (setq *answers* (cons (plug *thing* al) *answers*)))
        (t (findall (car pl) al (cdr pl)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;