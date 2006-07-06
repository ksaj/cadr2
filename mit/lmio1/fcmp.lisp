 ;;; LISP MACHINE FONT COMPILER  -*-LISP-*-
;	** (c) Copyright 1980 Massachusetts Institute of Technology **
		;RUNS INSIDE QCMP

(DECLARE (MUZZLED T))	;RASTER ROWS MAY BE BIGNUMS, MAYBE

(DECLARE (SPECIAL RASTER-WIDTH INDEXING-TABLE-REQUIRED CHARACTER-WIDTH
		  CHARACTER-WIDTH-VARIABLE LEFT-KERN-PRESENT RASTER-HEIGHT
		  HEIGHT BASELINE FASL-OP-INITIALIZE-ARRAY 
		  FASL-OP-STOREIN-SYMBOL-VALUE FASL-OP-PACKAGE-SYMBOL
		  FASL-OP-INITIALIZE-NUMERIC-ARRAY FASD-GROUP-LENGTH
		  RASTERS-PER-WORD WORDS-PER-CHAR EXTRA-BITS
		  BLINKER-HEIGHT BLINKER-WIDTH 32-BIT-MODE))

(DECLARE (FIXNUM M N I J K CH))

(DECLARE (ARRAY* (FIXNUM (LEFT-KERN 200) (RASTER-WIDTH 200) (CHARACTER-WIDTH 200))
		 (FIXNUM (INDEXING-TABLE 201))
		 (NOTYPE (RAST 200 ?)) (FIXNUM (QRAST ?))))

(DECLARE (FIXNUM (FASD-TABLE-ENTER NOTYPE NOTYPE))
	 (NOTYPE (FASD-START-GROUP NOTYPE FIXNUM FIXNUM)
		 (FASD-FIXED FIXNUM)
		 (FASD-INITIALIZE-ARRAY FIXNUM NOTYPE)
		 (FASD-INDEX FIXNUM)
		 (FASD-EVAL FIXNUM)
		 (FASD-NIBBLE FIXNUM)))

(DEFUN FCMP (FN)	;(FCMP 'FN1)
  (FCMP-1 FN FN FN T))		;THIS MAKES 32 BIT FONTS NOW

(DEFUN FCMP-16 (IFN OFN)
  (FCMP-1 IFN OFN OFN NIL))

;Arguments are FN1 of input file (AST), FN1 of output file (QFASL),
;symbol in FONTS package to be setq'ed to font, and 32-bit-mode
(DEFUN FCMP-1 (INPUT-FILE-NAME OUTPUT-FILE-NAME SYMBOL 32-BIT-MODE)
  (SETQ FASL-OP-PACKAGE-SYMBOL 60);There hasn't been a QCMP made in ages...
  (ARRAY LEFT-KERN FIXNUM 200)
  (ARRAY RASTER-WIDTH FIXNUM 200)
  (ARRAY CHARACTER-WIDTH FIXNUM 200)
  (APPLY (FUNCTION UREAD) (LIST INPUT-FILE-NAME 'AST))
  (SETQ RASTER-WIDTH 0)
  (SETQ INDEXING-TABLE-REQUIRED NIL CHARACTER-WIDTH NIL CHARACTER-WIDTH-VARIABLE NIL)
  (SETQ LEFT-KERN-PRESENT NIL RASTER-HEIGHT 0)
  (TERPRI)
  (RD-AST)
  (UCLOSE)
  (COND ((NOT 32-BIT-MODE)
	 (COND ((> RASTER-WIDTH 16.)
		(SETQ RASTER-WIDTH 16.)			;WIDE FONT
		(SETQ INDEXING-TABLE-REQUIRED T))))
	(T
	 (COND ((> RASTER-WIDTH 32.)
		(SETQ RASTER-WIDTH 32.)			;WIDE FONT
		(SETQ INDEXING-TABLE-REQUIRED T)))))
  (SETQ RASTERS-PER-WORD (// 32. RASTER-WIDTH))
  (SETQ EXTRA-BITS (- 32. (* RASTERS-PER-WORD RASTER-WIDTH)))
  (SETQ WORDS-PER-CHAR (// (+ RASTER-HEIGHT (1- RASTERS-PER-WORD)) RASTERS-PER-WORD))
  (COND (INDEXING-TABLE-REQUIRED (QIFY-RASTER-HARD))
	(T (QIFY-RASTER-EASY)))
  (SETQ BLINKER-HEIGHT (+ BASELINE 2)
	BLINKER-WIDTH (MAX 3 (1- CHARACTER-WIDTH)))
;  (PRINT (LIST 'BLINKER-HEIGHT BLINKER-HEIGHT '==>))
;  (COND ((= (TYIPEEK) 40)
;	 (TYI))
;	((SETQ BLINKER-HEIGHT (READ)))) 
;  (PRINT (LIST 'BLINKER-WIDTH BLINKER-WIDTH '==>))
;  (COND ((= (TYIPEEK) 40)
;	 (TYI))
;	((SETQ BLINKER-WIDTH (READ)))) 
  (TERPRI)
  (AND 32-BIT-MODE (BIT-REVERSE-QRAST))
  (FASD-OPEN '(_FCMP_ OUTPUT))
  (FASDUMP-FONT SYMBOL)
  (FASD-CLOSE (LIST OUTPUT-FILE-NAME 'QFASL))
)

(DEFUN MAKE-COLD-FONT (FN)				;CALL THIS AFTER CALLING FCMP
  ((LAMBDA (^W ^R LEN)
    (OR (GET 'QRAST 'ARRAY)
	(ERROR '|FOO- NO STORED RASTER| FN))
    (UWRITE)
    (AND (OR CHARACTER-WIDTH-VARIABLE LEFT-KERN-PRESENT INDEXING-TABLE-REQUIRED)
	 (ERROR '|FOO- FONT IS TOO HAIRY| FN))
    (PRINT 'LEADER)
    (PRINT (LIST BLINKER-HEIGHT BLINKER-WIDTH
		 ;NEXT-PLANE QFIXT QFLKT QFCWT
	         NIL NIL NIL NIL
		 BASELINE WORDS-PER-CHAR
		 RASTERS-PER-WORD RASTER-WIDTH RASTER-HEIGHT
		 CHARACTER-WIDTH HEIGHT
		 FN 'FONT 0))
    (PRINT 'RASTER)
    (PRINT LEN)
    (DO I 0 (1+ I) (= I LEN) (PRINT (QRAST I)))
    (APPLY (FUNCTION UFILE) (LIST FN 'CLDFNT)))
   T
   T
   (CADR (ARRAYDIMS 'QRAST))))

(DEFUN QIFY-RASTER-EASY ()
  (ARRAY QRAST FIXNUM (* 200 WORDS-PER-CHAR))
  (FILLARRAY 'QRAST '(0))
  (DO CH 0 (1+ CH) (= CH 200)
    (DO N 0 (1+ N) (= N WORDS-PER-CHAR)
      (STORE (QRAST (+ (* CH WORDS-PER-CHAR) N))
	     (DO ((I 0 (1+ I))
		  (J (* N RASTERS-PER-WORD) (1+ J))
		  (K (- 32. RASTER-WIDTH) (- K RASTER-WIDTH))
		  (ROW 0))
		 ((NOT (AND (< J RASTER-HEIGHT) (< I RASTERS-PER-WORD)))
		  ROW)
	       (SETQ ROW (PLUS ROW (LSH (OR (RAST CH J) 0)
					(+ (- RASTER-WIDTH (RASTER-WIDTH CH)) K)))))))))

;HANDLE WIDE FONT THAT REQUIRES AN INDEXING TABLE
(DEFUN QIFY-RASTER-HARD ()
  (ARRAY MULTIPLICITY FIXNUM 200)			;# "COLUMNS" WIDE EACH CHAR IS
  (FILLARRAY 'MULTIPLICITY '(0))
  (ARRAY INDEXING-TABLE FIXNUM 201)
  (DO CH 0 (1+ CH) (= CH 200)
    (STORE (MULTIPLICITY CH) (// (1- (+ (RASTER-WIDTH CH) RASTER-WIDTH))
				 RASTER-WIDTH)))
  (STORE (INDEXING-TABLE 0) 0)
  (DO ((CH 0 (1+ CH))
       (IDX 0))
      ((= CH 200)
       (ARRAY QRAST FIXNUM (* IDX WORDS-PER-CHAR)))
    (SETQ IDX (+ IDX (MULTIPLICITY CH)))
    (STORE (INDEXING-TABLE (1+ CH)) IDX))
  (DO CH 0 (1+ CH) (= CH 200)				;FOR EACH CHARACTER
    (DO M 0 (1+ M) (= M (MULTIPLICITY CH))		;FOR EACH COLUMN
      (DO N 0 (1+ N) (= N WORDS-PER-CHAR)		;FOR EACH RASTER WORD
	(STORE (QRAST (+ N (* (+ (INDEXING-TABLE CH) M) WORDS-PER-CHAR)))
	       (DO ((I 0 (1+ I))			;FOR EACH ROW WITHIN A WORD
		    (J (* N RASTERS-PER-WORD) (1+ J))	;J IS ROW NUMBER FROM TOP OF CHAR
		    (K (- (RASTER-WIDTH CH) (* (1+ M) RASTER-WIDTH)))  ;K IS NUMBER OF BITS
							; TO SHIFT ROW RIGHT TO GET CURRENT
		    (ROW 0))				; COLUMN'S RASTER
		   ((NOT (AND (< J RASTER-HEIGHT) (< I RASTERS-PER-WORD)))
		    ROW)
		 (SETQ ROW				;STORE NEXT ROW INTO
		   (+ ROW (LSH				; WORD OF RASTER
			   (COND ((< K 0)		;GOTTA SHIFT LEFT (LAST COLUMN)
				  (BOOLE 1 (1- (LSH 1 RASTER-WIDTH))
					 (LSH (LOGLDB 0040 (OR (RAST CH J) 0))
					      (MINUS K))))
				 ((LOGLDB (+ (LSH K 6) RASTER-WIDTH)
					  (OR (RAST CH J) 0))))
			   (* (1- (- RASTERS-PER-WORD I)) RASTER-WIDTH) ))) ))))))

(DECLARE (FIXNUM (CIRC FIXNUM)))
(LAP CIRC SUBR)
(ARGS CIRC (NIL . 1))
	(PUSH P (% 0 0 FIX1))
	(MOVE T 0 (A))
	(LSH T 4)
	(CIRC T 32.)	;TT gets reversed bits left-adjusted
	(LSH TT -4)
	(POPJ P)
NIL 

(DEFUN BIT-REVERSE-QRAST ()
  (DO ((I 0 (1+ I))
       (N (CADR (ARRAYDIMS 'QRAST))))
      ((= I N))
   (DECLARE (FIXNUM I N))
   (STORE (QRAST I) (CIRC (QRAST I)))))

(DEFUN FASDUMP-FONT (FONTNAME)
  (PROG (QFCWT QFLKT QFIXT QFT QFONTNAME)
    (FASD-INITIALIZE)
;    (FASD-EVAL (FASD-CONSTANT '(SETQ LENGTH-OF-FASL-TABLE 1300)))	;KLUDGE KLUDGE KLUDGE
;    (FASD-END-WHACK)
    (AND CHARACTER-WIDTH-VARIABLE
	 (SETQ QFCWT (FASDUMP-FONT-SUB-ARRAY 'CHARACTER-WIDTH)))
    (AND LEFT-KERN-PRESENT
	 (SETQ QFLKT (FASDUMP-FONT-SUB-ARRAY 'LEFT-KERN)))
    (AND INDEXING-TABLE-REQUIRED
	 (SETQ QFIXT (FASDUMP-FONT-SUB-ARRAY 'INDEXING-TABLE)))
    (FASD-PACKAGE-SYMBOL (LIST 'FONTS FONTNAME))
    (SETQ QFONTNAME (FASD-TABLE-ENTER 'LIST FONTNAME))
    (SETQ QFT (FASD-MAKE-ARRAY 'WORKING-STORAGE-AREA 'ART-1B ;REALLY 32B, BUT 1B
		(LIST (* 32. (CADR (ARRAYDIMS 'QRAST)))) NIL       ;MAKES IT EASIER FOR
		(LIST NIL BLINKER-HEIGHT BLINKER-WIDTH		   ;LISP PROGRAMS.
		      NIL QFIXT QFLKT QFCWT BASELINE WORDS-PER-CHAR
		      RASTERS-PER-WORD RASTER-WIDTH RASTER-HEIGHT
		      CHARACTER-WIDTH HEIGHT
		      NIL 'FONT 0)
		'FONT))
    ;(FASD-STOREIN-SYMBOL-VALUE FONTNAME QFT)
    ((LAMBDA (FASD-GROUP-LENGTH)
	(FASD-START-GROUP NIL 1 FASL-OP-STOREIN-SYMBOL-VALUE)
	(FASD-NIBBLE QFT)
	(FASD-INDEX QFONTNAME))
     NIL)
    (AND QFCWT (FASD-STOREIN-ARRAY-LEADER QFT (FASD-CONSTANT 12) QFCWT))
    (AND QFLKT (FASD-STOREIN-ARRAY-LEADER QFT (FASD-CONSTANT 13) QFLKT))
    (AND QFIXT (FASD-STOREIN-ARRAY-LEADER QFT (FASD-CONSTANT 14) QFIXT))
    (FASD-STOREIN-ARRAY-LEADER QFT (FASD-CONSTANT 2) QFONTNAME)
    (FASDUMP-FONT-QRAST QFT)
    (FASD-END-OF-FILE)
))

(DEFUN FASDUMP-FONT-SUB-ARRAY (SYMB)
  (PROG (IDX N FASD-GROUP-LENGTH)
    (SETQ N (CADR (ARRAYDIMS SYMB)))
    (SETQ IDX (FASD-MAKE-ARRAY 'WORKING-STORAGE-AREA 'ART-Q
			(LIST N) NIL NIL))
    (FASD-START-GROUP NIL 0 FASL-OP-INITIALIZE-ARRAY)
    (FASD-INDEX IDX)
    (FASD-CONSTANT N)
    (DO I 0 (1+ I) (= I N) (FASD-CONSTANT (OR (FUNCALL SYMB I) 0)))
    (RETURN IDX)))

(DEFUN FASDUMP-FONT-QRAST (IDX)
  (PROG (N FASD-GROUP-LENGTH)
    (SETQ N (CADR (ARRAYDIMS 'QRAST)))
    (FASD-START-GROUP NIL 0 FASL-OP-INITIALIZE-NUMERIC-ARRAY)
    (FASD-INDEX IDX)
    (FASD-CONSTANT (* 2 N))
    (DO I 0 (1+ I) (= I N)
	(FASD-NIBBLE (BOOLE 1 177777 (QRAST I)));RIGHT 16 BITS
	(FASD-NIBBLE (LSH (QRAST I) -16.))	;LEFT 16 BITS
)))

(DEFUN RD-AST ()
  (PROG (CC RW RRW CW LK ^Q)
    (DECLARE (FIXNUM CC RW RRW CW LK I))
    (SETQ ^Q T)
    (RD-AST-DN)		;KSTID
    (SETQ HEIGHT (RD-AST-DN))
    (SETQ BASELINE (RD-AST-DN))
    (RD-AST-DN)		;COLUMN POSITION ADJUSTMENT
    (ARRAY RAST T 200 HEIGHT)
    (FILLARRAY 'RAST '(NIL))
A   (COND ((NULL (RD-AST-NEXT-PAGE))
	   (RETURN T)))
    (SETQ CC (RD-AST-ON))
    (SETQ RRW (RD-AST-DN) RW RRW)
    (SETQ CW (RD-AST-DN))
    (SETQ LK (RD-AST-DN))
    (COND ((= LK 0))
	  ((< LK 0)			;FED COMPACT RASTER LOSSAGE
	   (SETQ RW (- RW LK))
	   (SETQ LK 0))
	  ((SETQ LEFT-KERN-PRESENT T)))
    (SETQ RASTER-WIDTH (MAX RASTER-WIDTH RW))
    (COND ((NULL CHARACTER-WIDTH)
	   (SETQ CHARACTER-WIDTH CW))
	  ((= CHARACTER-WIDTH CW))
	  (T (AND (ZEROP CHARACTER-WIDTH)
		  (SETQ CHARACTER-WIDTH CW))
	     (SETQ CHARACTER-WIDTH-VARIABLE T)))
    (DO I 0 (1+ I) (= I HEIGHT)
	(STORE (RAST CC I) (OR (RD-AST-ROW RRW) (RETURN NIL)))
	(SETQ RASTER-HEIGHT (MAX (1+ I) RASTER-HEIGHT)))
    (STORE (LEFT-KERN CC) LK)
    (STORE (RASTER-WIDTH CC) RW)
    (STORE (CHARACTER-WIDTH CC) CW)
    (COND ((> CC 37) (TYO CC))
	  (T (PRINC '^) (TYO (+ 100 CC))))
    (GO A)))

(DEFUN RD-AST-ROW (SHIFT)
  (PROG (CH ROW)	;ROW MAY BE BIGNUM
    (AND (OR (= (SETQ CH (TYIPEEK)) 14) (= CH 3) (< CH 0))
	 (RETURN NIL))
    (SETQ ROW 0)
A   (SETQ SHIFT (1- SHIFT))
    (AND (< (SETQ CH (TYI)) 40)
	 (GO B))
    (OR (= CH 40) (SETQ ROW (PLUS ROW (EXPT 2 SHIFT))))
    (GO A)

B   (AND (= CH 12) (RETURN ROW))
    (SETQ CH (TYI))
    (GO B)))

(DEFUN RD-AST-DN ()
  (PROG (N CH SIGN)
    (SETQ N 0 SIGN 1)
    (SETQ CH (TYI))		;LOOK FOR MINUS SIGN
    (COND ((= CH 55)
	   (SETQ SIGN -1))
	  (T (GO AA)))
A   (SETQ CH (TYI))
AA  (AND (> CH 57) (< CH 72) (PROGN
	(SETQ N (+ (* N 10.) (- CH 60)))
	(GO A)))
B   (AND (= CH 12) (RETURN (* N SIGN)))
    (SETQ CH (TYI))
    (GO B)))

(DEFUN RD-AST-ON ()
  (PROG (N CH)
    (SETQ N 0)
A   (SETQ CH (TYI))
    (AND (> CH 57) (< CH 70) (PROGN
	(SETQ N (+ (* N 8) (- CH 60)))
	(GO A)))
B   (AND (= CH 12) (RETURN N))
    (SETQ CH (TYI))
    (GO B)))

(DEFUN RD-AST-NEXT-PAGE ()
  (PROG (CH)
    (COND ((= (SETQ CH (TYI -1)) 14)
	   (AND (OR (= (SETQ CH (TYIPEEK)) 3) (< CH 0))
		(RETURN NIL))
	   (RETURN T))
	  ((= CH 3) (RETURN NIL))
	  ((= CH -1) (RETURN NIL))
	  ((ERROR '|RANDOM CHAR WHERE FF EXPECTED| CH 'FAIL-ACT)))))
