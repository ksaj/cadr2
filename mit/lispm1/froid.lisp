;LISP MACHINE FASLOAD				-*-LISP-*-
;	** (c) Copyright 1980 Massachusetts Institute of Technology **
;This version is intended to read QFASL files into a cold-load.
;Compiles in QCOMPLR only.

(DECLARE
  ;Get double-quote, macros, etc.
  (COND ((NULL (MEMQ 'NEWIO (STATUS FEATURES)))
	 (BREAK 'YOU-HAVE-TO-COMPILE-THIS-WITH-QCOMPL T))
	((NULL (GET 'IF-FOR-MACLISP 'MACRO))
	 (LOAD '(MACROS > DSK LISPM))
	 (LOAD '(DEFMAC FASL DSK LISPM2))
	 (LOAD '(LMMAC > DSK LISPM2))))
  (MACROS NIL) ;MAKE PLENTY DAMN SURE THESE AR-1 MACROS AREN'T AROUND IN THE COLD LOAD GENERATOR
  (SPECIAL EVALS-TO-BE-SENT-OVER
	   LAST-FASL-EVAL  ;THE ELEMENT OF EVALS-TO-BE-SENT-OVER CREATED BY THE LAST 
			   ; FASL-OP-EVAL.
	   COLD-LIST-AREA CURRENT-FUNCTION)
)

(DECLARE (EVAL (READ)))
       (DEFUN **STRING** MACRO (X) `',(CADR X)) ;Bubbles in my brain

(DECLARE (FIXNUM (LOGLDB-FROM-FIXNUM FIXNUM FIXNUM)
		 (LOGDPB-INTO-FIXNUM FIXNUM FIXNUM FIXNUM)))
(DECLARE (FIXNUM (QFASL-NIBBLE)
		 (QFASL-NEXT-NIBBLE)))
(DECLARE (NOTYPE (STORE-HALFWORD FIXNUM)))

;SYMBOLS FROM QCOM

(DECLARE (SPECIAL %%ARRAY-TYPE-FIELD %%ARRAY-LEADER-BIT %%ARRAY-DISPLACED-BIT
		  %%ARRAY-FLAG-BIT %%ARRAY-NUMBER-DIMENSIONS %%ARRAY-LONG-LENGTH-FLAG
		  %%ARRAY-INDEX-LENGTH-IF-SHORT ARRAY-TYPES ARRAY-ELEMENTS-PER-Q
		  %HEADER-TYPE-ARRAY-LEADER %%HEADER-TYPE-FIELD ARRAY-BITS-PER-ELEMENT
		  DTP-TRAP DTP-NULL DTP-FREE 
		  DTP-SYMBOL DTP-SYMBOL-HEADER DTP-FIX DTP-EXTENDED-NUMBER 
		  DTP-HEADER 
		  DTP-GC-FORWARD DTP-EXTERNAL-VALUE-CELL-POINTER DTP-ONE-Q-FORWARD
		  DTP-HEADER-FORWARD DTP-BODY-FORWARD
		  DTP-LOCATIVE
		  DTP-LIST 
		  DTP-U-ENTRY 
		  DTP-FEF-POINTER DTP-ARRAY-POINTER DTP-ARRAY-HEADER 
		  DTP-STACK-GROUP DTP-CLOSURE
		  CDR-NIL CDR-NEXT 
		  QNIL ARRAY-DIM-MULT
))

;FASLOAD TYPE SYMBOLS FROM QCOM OR QDEFS OR SOMEPLACE.

(DECLARE (SPECIAL LENGTH-OF-FASL-TABLE FASL-TABLE-WORKING-OFFSET FASL-OPS
		  FASL-SYMBOL-HEAD-AREA FASL-SYMBOL-STRING-AREA
		  FASL-OBARRAY-POINTER FASL-ARRAY-AREA FASL-FRAME-AREA
		  FASL-LIST-AREA FASL-TEMP-LIST-AREA FDEFINE-FILE-SYMBOL
		  FASL-MICRO-CODE-EXIT-AREA FASL-RETURN-FLAG
		  FASL-GROUP-FLAG FASL-GROUP-BITS FASL-GROUP-TYPE FASL-GROUP-LENGTH
		  %FASL-GROUP-CHECK %FASL-GROUP-FLAG %%FASL-GROUP-LENGTH
		  %FASL-GROUP-TYPE LENGTH-OF-ATOM-HEAD
		  %ARRAY-LEADER-LENGTH %%ARRAY-INDEX-LENGTH-IF-SHORT
		  FASL-EVALED-VALUE LIST-STRUCTURED-AREAS
		  CDR-CODES ;DEFINED IN COLD
		  DATA-TYPES ;DEFINED IN QCOM
))

(DECLARE (SPECIAL FASL-TABLE FASL-TABLE-FILL-POINTER
		  Q-FASL-GROUP-DISPATCH Q-FASL-GROUP-DISPATCH-FAST FASL-GROUP-DISPATCH-SIZE
		  M-FASL-GROUP-DISPATCH M-FASL-GROUP-DISPATCH-FAST))

(DECLARE (SPECIAL QFASL-BINARY-FILE))

;Q-FASL-xxxx refers to functions which load into the cold load, and
; return a "Q", i.e. a list of data-type and address-expression.
;M-FASL-xxxx refers to functions which load into Maclisp, and
; return a Lisp object.
;In the FASL-TABLE, each entry in both the prefix and the main part
; is a list whose car is the Maclisp value and whose cadr is either
; NIL or the Q-value.  If it needs a Q-value and one hasn't been
; computed yet, it will compute one, but this may put it in the wrong area.

;These functions are used to refer to the FASL-TABLE

;For typing convenience
(DEFMACRO AR-1 (AR I)
  `(ARRAYCALL T ,AR ,I))

(DEFMACRO AS-1 (V AR I)
  `(STORE (ARRAYCALL T ,AR ,I) ,V))

(DEFMACRO LOGAND X `(BOOLE 1 .,X))

(DEFMACRO LOGIOR X `(BOOLE 7 .,X))

(DEFMACRO LOGXOR X `(BOOLE 6 .,X))

;Get a Q
(DEFUN Q-ARFT (X)
  (COND ((ATOM (SETQ X (ARRAYCALL T FASL-TABLE X)))
	 (ERROR "NOT A Q - Q-ARFT" X 'FAIL-ACT))
	((CADR X))
	(T (RPLACA (CDR X) (MAKE-Q-LIST 'INIT-LIST-AREA (CAR X)))
	   (CADR X))))

;Get a Maclisp object
(DEFUN M-ARFT (X)
  (COND ((ATOM (SETQ X (ARRAYCALL T FASL-TABLE X)))
	 (ERROR "NOT A Q - M-ARFT" X 'FAIL-ACT))
	(T (CAR X))))

;Store a Maclisp object
(DEFMACRO M-ASFT (D X)
  `(STORE (ARRAYCALL T FASL-TABLE ,X) (LIST ,D NIL)))

;Store a Maclisp object and a Q
(DEFMACRO M-Q-ASFT (D Q X)
  `(STORE (ARRAYCALL T FASL-TABLE ,X) (LIST ,D ,Q)))

(ARRAY QFASL-NIBBLE-BUFFER FIXNUM 1)

;(DEFPROP USER/:SOURCE-FILE-NAME (USER SOURCE-FILE-NAME) PACKAGE-PATH)

(DEFUN COLD-FASLOAD (FILESPEC)
 (PROG (QFASL-BINARY-FILE FDEFINE-FILE-SYMBOL)
       (OR (BOUNDP 'Q-FASL-GROUP-DISPATCH) (INITIALIZE-FASL-ENVIRONMENT))
       (SETQ FILESPEC (MERGEF FILESPEC '|DSK:LISPM;* QFASL|))
       (PRINT (LIST 'COLD-FASLOAD FILESPEC) MSGFILES) ;REPORT
       (SETQ QFASL-BINARY-FILE (OPEN FILESPEC '(IN BLOCK FIXNUM)))
       (SETQ FDEFINE-FILE-SYMBOL
	     (QINTERN (IMPLODE (APPEND '(A I /: / )
				       (EXPLODEN (CADAR FILESPEC))
				       '(/; / )
				       (EXPLODEN (CADR FILESPEC))
				       '(/  />)))))
       (STORE-DATA-CONTENTS	;Set package cell to FILES
	  (LIST (CAADR FDEFINE-FILE-SYMBOL) (+ 4 (CADADR FDEFINE-FILE-SYMBOL)))
	  (QINTERN 'FILES))
       (STORE (QFASL-NIBBLE-BUFFER 0) -1)
       (COND ((= (IN QFASL-BINARY-FILE) -163136142400)	;SIXBIT QFASL
	      (DO ()
		  ((EQ (QFASL-WHACK) 'EOF)
		   T))
	      (CLOSE QFASL-BINARY-FILE))
	     (T (ERROR "NOT A QFASL FILE" QFASL-BINARY-FILE 'FAIL-ACT)))
       (RETURN FILESPEC)))

;This is the function which gets a 16-bit "nibble" from the fasl file.
(DEFUN QFASL-NIBBLE ()
  ((LAMBDA (TEM)
     (DECLARE (FIXNUM TEM))
     (COND ((< (SETQ TEM (QFASL-NIBBLE-BUFFER 0)) 0)
	    (SETQ TEM (IN QFASL-BINARY-FILE))
	    (STORE (QFASL-NIBBLE-BUFFER 0) (BOOLE 1 177777 (LSH TEM -4)))
	    (LSH TEM -24))
	   (T (STORE (QFASL-NIBBLE-BUFFER 0) -1)
	      TEM)))
   0))

;This function processes one "whack" (independent section) of a fasl file.
(DEFUN QFASL-WHACK NIL 
  (PROG (FASL-RETURN-FLAG FASL-TABLE-FILL-POINTER)
	(OR (BOUNDP 'FASL-TABLE)
	    (SETQ FASL-TABLE (*ARRAY NIL T LENGTH-OF-FASL-TABLE)))
	(FILLARRAY FASL-TABLE '(NIL))
	(INITIALIZE-QFASL-TABLE)
	(SETQ FASL-TABLE-FILL-POINTER FASL-TABLE-WORKING-OFFSET)
  L	(QFASL-GROUP NIL)
	(COND (FASL-RETURN-FLAG 
		(RETURN FASL-RETURN-FLAG)))
	(GO L)
))

;Initialize FASL-TABLE prefix
(DEFUN INITIALIZE-QFASL-TABLE NIL 
	(AS-1 '(NR-SYM NIL) FASL-TABLE FASL-SYMBOL-HEAD-AREA)
	(AS-1 '(P-N-STRING NIL) FASL-TABLE FASL-SYMBOL-STRING-AREA)
;	(AS-1 OBARRAY FASL-TABLE FASL-OBARRAY-POINTER)
	(AS-1 '(CONTROL-TABLES NIL) FASL-TABLE FASL-ARRAY-AREA) ;I GUESS
	(AS-1 '(MACRO-COMPILED-PROGRAM NIL) FASL-TABLE FASL-FRAME-AREA)
	(AS-1 '(INIT-LIST-AREA NIL) FASL-TABLE FASL-LIST-AREA) ;NOT FASL-CONSTANTS-AREA!!
	(AS-1 '(FASL-TEMP-AREA NIL) FASL-TABLE FASL-TEMP-LIST-AREA)
	(AS-1 '(MICRO-CODE-EXIT-AREA NIL) FASL-TABLE FASL-MICRO-CODE-EXIT-AREA)
)

(DEFUN INITIALIZE-FASL-ENVIRONMENT NIL
  (COND ((NOT (BOUNDP 'FASL-OPS))
	 (PRINC '|; READING IN QDEFS |)
	 (READFILE '(QDEFS > DSK LISPM))
	 (TERPRI)))
  (SETQ FASL-GROUP-DISPATCH-SIZE (LENGTH FASL-OPS))
  (SETQ Q-FASL-GROUP-DISPATCH (*ARRAY NIL T FASL-GROUP-DISPATCH-SIZE))
  (SETQ Q-FASL-GROUP-DISPATCH-FAST (*ARRAY NIL T FASL-GROUP-DISPATCH-SIZE))
  (SETQ M-FASL-GROUP-DISPATCH (*ARRAY NIL T FASL-GROUP-DISPATCH-SIZE))
  (SETQ M-FASL-GROUP-DISPATCH-FAST (*ARRAY NIL T FASL-GROUP-DISPATCH-SIZE))
  (DO ((I 0 (1+ I))
       (L FASL-OPS (CDR L))
       (M-OP) (Q-OP) (TEM))
      ((= I FASL-GROUP-DISPATCH-SIZE))
    (SETQ M-OP (IMPLODE (CONS 'M (SETQ TEM (CONS '- (EXPLODEN (CAR L))))))
	  Q-OP (IMPLODE (CONS 'Q TEM)))
    (AS-1 M-OP M-FASL-GROUP-DISPATCH I)
    (COND ((SETQ TEM (GET M-OP 'SUBR))
	   (AS-1 TEM M-FASL-GROUP-DISPATCH-FAST I))
	  (T
	   (AS-1 (GET 'M-FASL-OP-ERR 'SUBR) M-FASL-GROUP-DISPATCH-FAST I)))
    (AS-1 Q-OP Q-FASL-GROUP-DISPATCH I)
    (COND ((SETQ TEM (GET Q-OP 'SUBR))
	   (AS-1 TEM Q-FASL-GROUP-DISPATCH-FAST I))
	  (T
	   (AS-1 (GET 'Q-FASL-OP-ERR 'SUBR) Q-FASL-GROUP-DISPATCH-FAST I)))))

;Process one "group" (a single operation)
;Argument is NIL for Q-FASL, T for M-FASL.
(DEFUN QFASL-GROUP (MACLISP-P)
  (PROG (FASL-GROUP-FLAG FASL-GROUP-BITS FASL-GROUP-TYPE FASL-GROUP-LENGTH)
	(SETQ FASL-GROUP-BITS (QFASL-NIBBLE))
	(COND ((= 0 (LOGAND FASL-GROUP-BITS %FASL-GROUP-CHECK))
		(ERROR 'FASL-GROUP-NIBBLE-WITHOUT-CHECK-BIT FASL-GROUP-BITS 'FAIL-ACT)))
	(SETQ FASL-GROUP-FLAG (NOT (= 0 (LOGAND FASL-GROUP-BITS %FASL-GROUP-FLAG))))
	(SETQ FASL-GROUP-LENGTH (LOGLDB-FROM-FIXNUM %%FASL-GROUP-LENGTH FASL-GROUP-BITS))
	(AND (= FASL-GROUP-LENGTH 377)
	     (SETQ FASL-GROUP-LENGTH (QFASL-NIBBLE)))
	(SETQ FASL-GROUP-TYPE (LOGAND FASL-GROUP-BITS %FASL-GROUP-TYPE))
	(OR (< FASL-GROUP-TYPE FASL-GROUP-DISPATCH-SIZE)
	    (ERROR '|ERRONEOUS FASL GROUP TYPE| FASL-GROUP-TYPE 'FAIL-ACT))
	(RETURN
	  (COND	(NOUUO
		 (COND (MACLISP-P
			(FUNCALL (ARRAYCALL T M-FASL-GROUP-DISPATCH FASL-GROUP-TYPE)))
		       ((FUNCALL (ARRAYCALL T Q-FASL-GROUP-DISPATCH FASL-GROUP-TYPE)))))
		(MACLISP-P
		 (SUBRCALL NIL (ARRAYCALL T M-FASL-GROUP-DISPATCH-FAST FASL-GROUP-TYPE)))
		((SUBRCALL NIL (ARRAYCALL T Q-FASL-GROUP-DISPATCH-FAST FASL-GROUP-TYPE))))) ))

;Get next nibble out of current group
(DEFUN QFASL-NEXT-NIBBLE NIL 
	(COND ((ZEROP FASL-GROUP-LENGTH)
	       (ERROR "FASL-GROUP-OVERFLOW" NIL 'FAIL-ACT))
	      (T (SETQ FASL-GROUP-LENGTH (1- FASL-GROUP-LENGTH))
		 (QFASL-NIBBLE))))

;Get next value for current group.  Works by recursively evaluating a group.
;This one gets a Q value
(DEFUN Q-FASL-NEXT-VALUE NIL 
  (Q-ARFT (QFASL-GROUP NIL)))

;This one gets an M value
(DEFUN M-FASL-NEXT-VALUE NIL
  (M-ARFT (QFASL-GROUP T)))

;FASL-OP's that create a value end up by calling this.  The value is saved
;away in the FASL-TABLE for later use, and the index is returned (as the 
;result of QFASL-GROUP).
;This one enters a Maclisp object and a Q
(DEFUN M-Q-ENTER-FASL-TABLE (M Q)
  (COND ((NOT (< FASL-TABLE-FILL-POINTER LENGTH-OF-FASL-TABLE))
	 (ERROR '|FASL TABLE OVERFLOW| (LIST M Q) 'FAIL-ACT))
	(T
	 (M-Q-ASFT M Q FASL-TABLE-FILL-POINTER)
	 (PROG2 NIL FASL-TABLE-FILL-POINTER
		    (SETQ FASL-TABLE-FILL-POINTER (1+ FASL-TABLE-FILL-POINTER))))))

;This one enters an M value
(DEFUN M-ENTER-FASL-TABLE (V)
  (COND ((NOT (< FASL-TABLE-FILL-POINTER LENGTH-OF-FASL-TABLE))
	 (ERROR '|FASL TABLE OVERFLOW| V 'FAIL-ACT))
	(T
	 (M-ASFT V FASL-TABLE-FILL-POINTER)
	 (PROG2 NIL FASL-TABLE-FILL-POINTER
		    (SETQ FASL-TABLE-FILL-POINTER (1+ FASL-TABLE-FILL-POINTER))))))

;--M-FASL OPS

(DEFUN M-FASL-OP-ERR NIL
       (ERROR "UNIMPLEMENTED M-FASL-OP ENCOUNTERED" (NTH FASL-GROUP-TYPE FASL-OPS) 'FAIL-ACT))

(DEFUN M-FASL-OP-NOOP NIL 0)

(DEFUN M-FASL-OP-INDEX NIL (QFASL-NEXT-NIBBLE))

(DEFUN M-FASL-OP-STRING ()  ;USE THE **STRING** CONVENTION
  (M-ENTER-FASL-TABLE (LIST '**STRING** (MAKNAM (M-FASL-PNAME)))))

(DEFUN M-FASL-OP-SYMBOL ()
  (M-ENTER-FASL-TABLE (COND (FASL-GROUP-FLAG (MAKNAM (M-FASL-PNAME)))
			    (T (IMPLODE (M-FASL-PNAME))))))

(DEFUN M-FASL-OP-PACKAGE-SYMBOL ()
  (DO ((I 0 (1+ I))
       (PATH NIL)
       (SYM)
       (LEN (QFASL-NEXT-NIBBLE)))
      ((= I LEN) 
       (SETQ PATH (NREVERSE PATH))
       (COND ((OR (SAMEPNAMEP (CAR PATH) 'SI)
		  (SAMEPNAMEP (CAR PATH) 'SYSTEM-INTERNALS)) ;Don't get faked out
	      (M-ENTER-FASL-TABLE (INTERN (CADR PATH))))
	     (T
	      (SETQ SYM (IMPLODE (MAPCON (FUNCTION (LAMBDA (L)
					       (NCONC (EXPLODEN (CAR L))
						      (AND (CDR L) (LIST '/:)))))
					 PATH)))
	      (PUTPROP SYM PATH 'PACKAGE-PATH)
	      (M-ENTER-FASL-TABLE SYM))))
    (SETQ PATH (CONS (INTERN (CADR (M-FASL-NEXT-VALUE)))  ;The CADR strips string to pname
		     PATH))))	;The INTERN causes winnage later when STORE-SYMBOL-VECTOR
				;calls QINTERN on the package name
(DEFUN M-FASL-PNAME ()	;RETURN A LIST OF CHARACTERS
  (PROG (TEM LST)
	(DECLARE (FIXNUM TEM))
   LP	(COND ((= 0 FASL-GROUP-LENGTH) (GO X)))
	(SETQ TEM (QFASL-NEXT-NIBBLE))
	(SETQ LST (CONS (LOGAND TEM 377) LST))
	(COND ((= (SETQ TEM (LSH TEM -8)) 200)
		(GO X)))
	(SETQ LST (CONS TEM LST))
	(GO LP)
   X	(RETURN (NREVERSE LST))))

;Generate a FIXNUM (or BIGNUM) value.
(DEFUN M-FASL-OP-FIXED NIL 
  (DO ((POS (* (1- FASL-GROUP-LENGTH) 20) (- POS 20))
       (C FASL-GROUP-LENGTH (1- C))
       (ANS 0))
      ((ZEROP C) (COND (FASL-GROUP-FLAG (SETQ ANS (MINUS ANS))))
		 (M-ENTER-FASL-TABLE ANS))
    (DECLARE (FIXNUM POS C))
    (SETQ ANS (LOGDPB (QFASL-NEXT-NIBBLE) (+ (LSH POS 6) 20) ANS))))

(DEFUN M-FASL-OP-FLOAT ()
  (Q-FASL-OP-FLOAT))

(DEFUN M-FASL-OP-LIST () (Q-FASL-OP-LIST))

(DEFUN M-FASL-OP-LIST1 NIL
  (PROG (LIST-LENGTH LST ADR TEM)
	(DECLARE (FIXNUM LIST-LENGTH))
	(SETQ LIST-LENGTH (QFASL-NEXT-NIBBLE))
  L	(COND ((= 0 LIST-LENGTH)
		(GO X)))
	(COND ((AND FASL-GROUP-FLAG (= LIST-LENGTH 1)) ;DOTTED
	       (RPLACD ADR (M-FASL-NEXT-VALUE)))
	      (T
	       (SETQ TEM (NCONS (M-FASL-NEXT-VALUE)))
	       (AND ADR (RPLACD ADR TEM))
	       (OR LST (SETQ LST TEM))
	       (SETQ ADR TEM)))
	(SETQ LIST-LENGTH (1- LIST-LENGTH))
	(GO L)
  X	(RETURN (M-Q-ENTER-FASL-TABLE LST '**SCREW**))
))

(DEFUN M-FASL-OP-TEMP-LIST NIL (M-FASL-OP-LIST1))

;--Q-FASL OPS

(DEFUN Q-FASL-OP-ERR NIL
       (ERROR "UNIMPLEMENTED Q-FASL-OP ENCOUNTERED" (NTH FASL-GROUP-TYPE FASL-OPS) 'FAIL-ACT))

(DEFUN Q-FASL-OP-NOOP NIL 0)

(DEFUN Q-FASL-OP-INDEX NIL (QFASL-NEXT-NIBBLE))

;Dont try to make MACLISP symbol since the character set is not general enuf.
(DEFUN Q-FASL-OP-STRING NIL 
  (PROG (TEM LST CHLIST)
;FIRST, GET CHLIST
   LP	(COND ((= 0 FASL-GROUP-LENGTH) (GO X)))
	(SETQ TEM (QFASL-NEXT-NIBBLE))
	(SETQ LST (CONS (LOGAND TEM 377) LST))
	(COND ((= (SETQ TEM (LSH TEM -8)) 200)
		(GO X)))
	(SETQ LST (CONS TEM LST))
	(GO LP)
   X	(SETQ CHLIST (NREVERSE LST))
;NOW, DO SOMETHING USEFUL WITH IT
	(RETURN (M-Q-ENTER-FASL-TABLE
		   (LIST '**STRING-CHLIST** CHLIST)
		   (STORE-CHLIST 'P-N-STRING '(FOO) CHLIST)))))

(DEFUN Q-FASL-OP-PACKAGE-SYMBOL NIL 
  (LET ((X (M-FASL-OP-PACKAGE-SYMBOL)))
    (Q-ARFT X)
    X))

(DEFUN Q-FASL-OP-SYMBOL NIL 
  (PROG (TEM LST SYM)
;FIRST, GET AN UNINTERNED MACLISP SYMBOL
   LP	(COND ((= 0 FASL-GROUP-LENGTH) (GO X)))
	(SETQ TEM (QFASL-NEXT-NIBBLE))
	(SETQ LST (CONS (LOGAND TEM 377) LST))
	(COND ((= (SETQ TEM (LSH TEM -8)) 200)
		(GO X)))
	(SETQ LST (CONS TEM LST))
	(GO LP)
   X	(SETQ SYM (MAKNAM (NREVERSE LST)))
;NOW, DO SOMETHING USEFUL WITH IT
	(RETURN (M-Q-ENTER-FASL-TABLE
		   (COND (FASL-GROUP-FLAG SYM)
			 (T (SETQ SYM (INTERN SYM))))
		   (COND (FASL-GROUP-FLAG ;UNINTERNED
			    (STORE-SYMBOL-VECTOR SYM 'NR-SYM))
			 (T	;INTERN
			  (QINTERN SYM)))))))

(DEFUN Q-FASL-OP-FIXED NIL 
  (DO ((POS (* (1- FASL-GROUP-LENGTH) 20) (- POS 20))
       (C FASL-GROUP-LENGTH (1- C))
       (ANS 0))
      ((ZEROP C) (COND (FASL-GROUP-FLAG (SETQ ANS (MINUS ANS))))
		 (COND ((> (HAULONG ANS) 24.)
			(BREAK CANT-LOAD-BIGNUMS-INTO-COLD-LOAD T)))
		 (M-Q-ENTER-FASL-TABLE ANS (LIST 'QZFIX (BOOLE 1 77777777 ANS))))
    (DECLARE (FIXNUM POS C))
    (SETQ ANS (LOGDPB (QFASL-NEXT-NIBBLE) (+ (LSH POS 6) 20) ANS))))

(DEFUN Q-FASL-OP-FLOAT ()
  (OR FASL-GROUP-FLAG (BREAK LARGE-FLONUMS-NOT-SUPPORTED))
  (LET ((NUM (LOGDPB (QFASL-NEXT-NIBBLE) 2010 (QFASL-NEXT-NIBBLE))))
    (M-Q-ENTER-FASL-TABLE (LIST '**SMALL-FLONUM** NUM) (LIST 'QZSFLO NUM))))

;;; Total kludgery.  FASL-OP-TEMP-LIST makes a Maclisp list, assumed to be
;;; going to get fed to something like FASL-OP-ARRAY or FASL-OP-EVAL.
;;; FASL-OP-LIST, on the other hand, makes a Lisp machine list, assumed to
;;; be going to be used for something like a macro.  In either case the
;;; area specification in the FASL table is ignored.
;;; Hopefully this kludgery stands some chance of working.

(DEFUN Q-FASL-OP-TEMP-LIST ()
  (M-FASL-OP-LIST))
       
(DEFUN Q-FASL-OP-LIST ()
  (PROG (LIST-LENGTH LST ADR TEM AREA C-CODE MACLISP-LIST FASL-IDX)
	(DECLARE (FIXNUM LIST-LENGTH))
	(SETQ AREA COLD-LIST-AREA)
	(SETQ LIST-LENGTH (QFASL-NEXT-NIBBLE))
	(OR (MEMQ AREA LIST-STRUCTURED-AREAS)
	    (BARF AREA '|Q-FASL-OP-LIST IN NON-LIST-STRUCTURED AREA| 'BARF))
	(SETQ LST (LIST 'QZLIST (APPEND (SETQ ADR (ALLOCATE-BLOCK AREA LIST-LENGTH)) NIL)))
  L	(COND ((= 0 LIST-LENGTH)
	       (GO X)))
	(SETQ C-CODE (COND ((AND FASL-GROUP-FLAG (= LIST-LENGTH 2)) 'FULL-NODE)
			   ((AND FASL-GROUP-FLAG (= LIST-LENGTH 1)) 'NXTNOT)
			   ((= LIST-LENGTH 1) 'NXTNIL)
			   (T 'NXTCDR)))
	(SETQ FASL-IDX (QFASL-GROUP NIL))
	(STORE-CONTENTS ADR (CONS C-CODE (Q-ARFT FASL-IDX)))
	(SETQ MACLISP-LIST (NCONC MACLISP-LIST
				  (COND ((AND FASL-GROUP-FLAG (= LIST-LENGTH 1))
					 (M-ARFT FASL-IDX))
					((NCONS (M-ARFT FASL-IDX))))))
	(RPLACA (CDR ADR) (1+ (CADR ADR)))
	(SETQ LIST-LENGTH (1- LIST-LENGTH))
	(GO L)
  X	(RETURN (M-Q-ENTER-FASL-TABLE MACLISP-LIST LST))
))

;Array stuff

;FASL-OP-ARRAY arguments are
; <value>  Area 
; <value>  Type symbol
; <value>  The dimension or dimension list (use temp-list)
; <value>  Displace pointer (NIL if none)
; <value>  Leader (NIL, number, or list) (use temp-list)
; <value>  Index offset (NIL if none)
; <value>  Named-structure (only present if flag bit set)
(DEFUN Q-FASL-OP-ARRAY ()
  (LET ((FLAG FASL-GROUP-FLAG)
	(AREA (M-FASL-NEXT-VALUE))
	(TYPE-SYM (M-FASL-NEXT-VALUE))
	(DIMS (M-FASL-NEXT-VALUE))
	(DISPLACED-P (M-FASL-NEXT-VALUE))  ;IF NON-NIL, WILL IT WORK?
	(LEADER (MAPCAR (FUNCTION (LAMBDA (X) (MAKE-Q-LIST 'INIT-LIST-AREA X)))
			(M-FASL-NEXT-VALUE)))
	(INDEX-OFFSET (M-FASL-NEXT-VALUE)) ;IF NON-NIL, WILL IT WORK?
	(NAMED-STRUCTURE NIL)
	(ARRAY NIL) (DATA-LENGTH NIL))
     (SETQ AREA 'CONTROL-TABLES) ;kludge to not be immediate-write
     (COND (FLAG
	    (SETQ NAMED-STRUCTURE (M-FASL-NEXT-VALUE))))
     (SETQ ARRAY (INIT-Q-ARRAY-NAMED-STR AREA
					 NIL  ;RETURN LIST OF ADDRESS AND DATA-LENGTH
					 INDEX-OFFSET
					 TYPE-SYM
					 DIMS
					 DISPLACED-P
					 LEADER
					 NAMED-STRUCTURE))
     (SETQ DATA-LENGTH (CADR ARRAY)
	   ARRAY (LIST 'QZARYP (CAR ARRAY)))
     ;Now store the data area
     (COND ((CDR (ASSQ TYPE-SYM ARRAY-BITS-PER-ELEMENT)) ;NUMERIC
	    (DO I DATA-LENGTH (1- I) (= I 0)
	      (DECLARE (FIXNUM I))
	      (STOREQ AREA 0)))
	   (T
	    (COND ((AND NAMED-STRUCTURE (NOT LEADER))
		    (STOREQ AREA (QINTERN NAMED-STRUCTURE))
		    (SETQ DATA-LENGTH (1- DATA-LENGTH))))
	    (DO I DATA-LENGTH (1- I) (= I 0)
	      (DECLARE (FIXNUM I))
	      (STOREQ AREA QNIL))))
     (M-Q-ENTER-FASL-TABLE
       "NOTE - YOU HAVE BEEN SCREWED TO THE WALL BY AN ARRAY"
       ARRAY)))

;Get values and store them into an array.
(DEFUN Q-FASL-OP-INITIALIZE-ARRAY ()
  (PROG (ARRAY NUM HACK PTR HEADER LONG-FLAG NDIMS)
	(DECLARE (FIXNUM N NUM NDIMS))
	(SETQ HACK (QFASL-GROUP NIL))
	(SETQ ARRAY (Q-ARFT HACK))
	(OR (EQ (CAR ARRAY) 'QZARYP)
	    (ERROR '|FASL-OP-INITIALIZE-ARRAY of non-array| ARRAY 'FAIL-ACT))
	(SETQ NUM (M-FASL-NEXT-VALUE))	;NUMBER OF VALUES TO INITIALIZE WITH
	;TAKE HEADER APART TO FIND ADDRESS OF DATA
	(SETQ PTR (CADR ARRAY))
	(SETQ HEADER (CONTENTS PTR))
	(SETQ LONG-FLAG (MEMQ 'ARRAY-LONG-LENGTH-FLAG HEADER)
	      NDIMS (\ (// (CADR HEADER) ARRAY-DIM-MULT) 7))
	(AND (MEMQ 'ARRAY-DISPLACED-BIT HEADER)
	     (ERROR '|Attempt to initialize displaced array, give it up| ARRAY 'FAIL-ACT))
	(SETQ PTR (LIST (CAR PTR)
			(+ (CADR PTR)
			   (COND (LONG-FLAG 1) (T 0))
			   NDIMS)))
	(DO N NUM (1- N) (ZEROP N)	;INITIALIZE SPECIFIED NUM OF VALS
	  (STORE-CONTENTS PTR (Q-FASL-NEXT-VALUE))
	  (SETQ PTR (LIST (CAR PTR) (1+ (CADR PTR)))))
	(RETURN HACK)))

;Get 16-bit nibble and store them into an array.
(DEFUN Q-FASL-OP-INITIALIZE-NUMERIC-ARRAY ()
  (PROG (ARRAY NUM HACK PTR HEADER LONG-FLAG NDIMS)
	(DECLARE (FIXNUM N NUM NDIMS))
	(SETQ HACK (QFASL-GROUP NIL))
	(SETQ ARRAY (Q-ARFT HACK))
	(OR (EQ (CAR ARRAY) 'QZARYP)
	    (ERROR '|FASL-OP-INITIALIZE-ARRAY of non-array| ARRAY 'FAIL-ACT))
	(SETQ NUM (M-FASL-NEXT-VALUE))	;NUMBER OF VALUES TO INITIALIZE WITH
	;TAKE HEADER APART TO FIND ADDRESS OF DATA
	(SETQ PTR (CADR ARRAY))
	(SETQ HEADER (CONTENTS PTR))
	(SETQ LONG-FLAG (MEMQ 'ARRAY-LONG-LENGTH-FLAG HEADER)
	      NDIMS (\ (// (CADR HEADER) ARRAY-DIM-MULT) 7))
	(AND (MEMQ 'ARRAY-DISPLACED-BIT HEADER)
	     (ERROR '|Attempt to initialize displaced array, give it up| ARRAY 'FAIL-ACT))
	(SETQ PTR (LIST (CAR PTR)
			(+ (CADR PTR)
			   (COND (LONG-FLAG 1) (T 0))
			   NDIMS)))
	(DO N (// NUM 2) (1- N) (ZEROP N)	;INITIALIZE SPECIFIED NUM OF VALS
	  (STORE-CONTENTS PTR (+ (QFASL-NIBBLE)
				 (LSH (QFASL-NIBBLE) 16.)))
	  (SETQ PTR (LIST (CAR PTR) (1+ (CADR PTR)))))
	(COND ((NOT (ZEROP (BOOLE 1 1 NUM)))	;ODD, CATCH LAST NIBBLE
	       (STORE-CONTENTS PTR (QFASL-NIBBLE))))
	(RETURN HACK)))

(DEFUN QFASL-STORE-EVALED-VALUE (V)
  (AS-1 V FASL-TABLE FASL-EVALED-VALUE)
  FASL-EVALED-VALUE)

(DEFUN Q-FASL-OP-EVAL NIL
  (LET ((EXP (M-ARFT (QFASL-NEXT-NIBBLE))))
    (COND ((AND (NOT (ATOM EXP))
		(EQ (CAR EXP) 'RECORD-SOURCE-FILE-NAME)
		(NOT (ATOM (CADR EXP)))
		(EQ (CAADR EXP) 'QUOTE)
		(SYMBOLP (CADADR EXP)))
	   (STORE-SOURCE-FILE-NAME-PROPERTY (QINTERN (CADADR EXP))))
	  (T (SETQ EVALS-TO-BE-SENT-OVER
		   (SETQ LAST-FASL-EVAL (CONS EXP EVALS-TO-BE-SENT-OVER))))))
 (QFASL-STORE-EVALED-VALUE 'VALUE-ONLY-AVAILABLE-IN-THE-FUTURE))

(DEFUN Q-FASL-OP-MOVE NIL 
 (PROG (FROM TO)
	(SETQ FROM (QFASL-NEXT-NIBBLE))
	(SETQ TO (QFASL-NEXT-NIBBLE))
	(COND ((= TO 177777) (RETURN (M-Q-ENTER-FASL-TABLE (CAR (AR-1 FASL-TABLE FROM))
							   (CADR (AR-1 FASL-TABLE FROM)))))
	      (T (AS-1 (AR-1 FASL-TABLE FROM) FASL-TABLE TO)
		 (RETURN TO)))))

;Macrocompiled code

(DEFUN Q-FASL-OP-FRAME NIL 
  (LET ((Q-COUNT (QFASL-NEXT-NIBBLE))		;NUMBER OF BOXED QS
	(UNBOXED-COUNT (QFASL-NEXT-NIBBLE))	;NUMBER OF UNBOXED QS (HALF NUM INSTRUCTIONS)
	(FEF)					;THE FEF BEING CREATED
	(OBJ)
	(TEM)
	(OFFSET 0)
	(AREA 'MACRO-COMPILED-PROGRAM)		;(M-ARFT FASL-FRAME-AREA)
	)
     (DECLARE (FIXNUM Q-COUNT UNBOXED-COUNT OFFSET))
     (SETQ FASL-GROUP-LENGTH (QFASL-NEXT-NIBBLE))	;AMOUNT OF STUFF THAT FOLLOWS
     (SETQ FEF (LIST 'QZFEFP			;STORE HEADER Q
		     (STOREQ AREA (CONS 'QZHDR (CDR (Q-FASL-NEXT-VALUE))))))
     (QFASL-NEXT-NIBBLE)			;SKIP MODIFIER NIBBLE FOR HEADER Q
     (DO I 1 (1+ I) (>= I Q-COUNT)		;FILL IN BOXED QS
       (SETQ OBJ (Q-FASL-NEXT-VALUE))		;GET OBJECT TO BE STORED
       (SETQ TEM (QFASL-NEXT-NIBBLE))		;GET ULTRA-KLUDGEY MODIFIER
       (OR (ZEROP (SETQ OFFSET (LOGAND 17 TEM)))	;ADD OFFSET IF NECESSARY
	   (SETQ OBJ (APPEND OBJ (LIST OFFSET))))
       (AND (BIT-TEST 420 TEM)			;TRY NOT TO GET SHAFTED TOTALLY
	    (OR (EQ (CAR OBJ) 'QZSYM)
		(ERROR "ABOUT TO GET SHAFTED TOTALLY - Q-FASL-OP-FRAME" OBJ 'FAIL-ACT)))
       (AND (BIT-TEST 20 TEM)			;MAKE INTO EXTERNAL VALUE CELL POINTER
	    (SETQ OBJ (CONS 'QZEVCP (CDR OBJ))));DO NOT USE RPLACA HERE, YOU WILL GET SHAFTED
       (AND (BIT-TEST 400 TEM)			;MAKE INTO LOCATIVE
	    (SETQ OBJ (CONS 'QZLOC (CDR OBJ))))	;DO NOT USE RPLACA HERE, YOU WILL GET SHAFTED
       (SETQ OBJ (CONS (NTH (LOGAND 3 (LSH TEM -6)) CDR-CODES) OBJ))
       (AND (BIT-TEST 40 TEM)			;FLAG BIT
	    (SETQ OBJ (CONS '%Q-FLAG-BIT OBJ)))
       (STOREQ AREA OBJ))
     (BEGIN-STORE-HALFWORDS AREA UNBOXED-COUNT)	;NOW STORE THE UNBOXED QS
     (DO N (* UNBOXED-COUNT 2) (1- N) (ZEROP N)
       (DECLARE (FIXNUM N))
       (STORE-HALFWORD (QFASL-NEXT-NIBBLE)))
     (END-STORE-HALFWORDS)
     (M-Q-ENTER-FASL-TABLE
        "NOTE - YOU HAVE BEEN SCREWED TO THE WALL BY A FEF"
	FEF)))

(DEFUN Q-FASL-OP-FUNCTION-HEADER NIL 
  (PROG (F-SXH)
	(SETQ CURRENT-FUNCTION (M-FASL-NEXT-VALUE)
	      F-SXH (M-FASL-NEXT-VALUE))
	(RETURN 0)))

(DEFUN Q-FASL-OP-FUNCTION-END NIL
	0)

(DEFUN Q-FASL-STOREIN-SYMBOL-CELL (N PUT-SOURCE-FILE-NAME-PROPERTY)
 (DECLARE (FIXNUM N))
 (PROG (NEWP ADR DATA SYM NIB)
  (SETQ NIB (QFASL-NEXT-NIBBLE))
  (SETQ SYM (M-FASL-NEXT-VALUE))
  (COND ((= NIB FASL-EVALED-VALUE)     ;Setting symbol to result of evaluation
	 (COND ((ATOM SYM)	       ;Modify the entry in EVALS-TO-BE-SENT-OVER
		(COND ((NULL LAST-FASL-EVAL)
		       (BARF SYM 'INVALID-STOREIN-SYMBOL 'BARF)))
		(RPLACA LAST-FASL-EVAL
			`(SET ',SYM ,(CAR LAST-FASL-EVAL))) ;SETQ not in cold load!
		(GO X))
	       (T (BARF SYM 'MUST-BE-A-SYM-EVALED-VALUE 'BARF)))))
  (SETQ DATA (Q-ARFT NIB))
  (COND	((ATOM SYM)
	 (SETQ SYM (QINTERN SYM))
	 (STORE-DATA-CONTENTS (LIST (CAADR SYM) (+ (CADADR SYM) N)) DATA)
	 (COND (PUT-SOURCE-FILE-NAME-PROPERTY
		(STORE-SOURCE-FILE-NAME-PROPERTY SYM))))
	  ;; E.g. (DEFUN (FOO PROP) (X Y) BODY)
	  ;; - thinks it's storing function cell but really PUTPROP
	((NOT (= N 2))
	 (BARF SYM 'MUST-BE-A-SYMBOL 'BARF))
	(T (SETQ ADR (CADR (QINTERN (CAR SYM))))
	   (SETQ NEWP (LIST 'QZLIST 
			    (STOREQ 'PROPERTY-LIST-AREA 
				    (CONS 'NXTCDR (QINTERN (CADR SYM))))))
	   (STOREQ 'PROPERTY-LIST-AREA (CONS 'FULL-NODE DATA))
	   (STOREQ 'PROPERTY-LIST-AREA (CONS 'NXTNOT (CDR (CONTENTS (LIST (CAR ADR)
									  (+ (CADR ADR)
									     3))))))
	   (STOREPROP (CAR SYM) 3 NEWP)))
 X (RETURN 0)))

(DEFUN STORE-SOURCE-FILE-NAME-PROPERTY (SYM)
  (LET ((NEWP (LIST 'QZLIST
		    (STOREQ 'PROPERTY-LIST-AREA
			    (CONS 'NXTCDR (QINTERN 'SOURCE-FILE-NAME))))))
						;Was USER/:SOURCE-FILE-NAME
    (STOREQ 'PROPERTY-LIST-AREA (CONS 'FULL-NODE FDEFINE-FILE-SYMBOL))
    (STOREQ 'PROPERTY-LIST-AREA
	    (CONS 'NXTNOT
		  (CDR (CONTENTS (LIST (CAADR SYM) (+ (CADADR SYM) 3))))))
    (STORE-DATA-CONTENTS (LIST (CAADR SYM) (+ (CADADR SYM) 3)) NEWP)))

(DEFUN Q-FASL-OP-STOREIN-SYMBOL-VALUE ()
  (Q-FASL-STOREIN-SYMBOL-CELL 1 NIL))

(DEFUN Q-FASL-OP-STOREIN-FUNCTION-CELL ()
  (Q-FASL-STOREIN-SYMBOL-CELL 2 T))

(DEFUN Q-FASL-OP-STOREIN-PROPERTY-CELL ()
  (Q-FASL-STOREIN-SYMBOL-CELL 3 NIL))

(DEFUN Q-FASL-OP-STOREIN-ARRAY-LEADER NIL
   (PROG (ARRAY SUBSCR VALUE)
	(SETQ ARRAY (Q-ARFT (QFASL-NEXT-NIBBLE)))
	(SETQ SUBSCR (M-ARFT (QFASL-NEXT-NIBBLE)))
	(SETQ VALUE (Q-ARFT (QFASL-NEXT-NIBBLE)))
	;ERROR CHECKING MIGHT BE NICE
	;(STORE-ARRAY-LEADER VALUE ARRAY SUBSCR)
	(STORE-CONTENTS (LIST (CAADR ARRAY) (- (CADADR ARRAY) (+ 2 SUBSCR))) VALUE)
	(RETURN 0)))

(DEFUN Q-FASL-FETCH-SYMBOL-CELL (N)
  (DECLARE (FIXNUM N))
  (LET ((SYM (Q-FASL-NEXT-VALUE)))
    (DO ((Q (CONTENTS (LIST (CAADR SYM) (+ (CADADR SYM) N)))
	    (CDR Q)))				;STRIP CDR CODE, ETC.
	((MEMQ (CAR Q) DATA-TYPES) Q)
      (AND (NULL Q)
	   (ERROR "SHAFTED TOTALLY - Q-FASL-FETCH-SYMBOL-CELL" N 'FAIL-ACT)))))

(DEFUN Q-FASL-OP-FETCH-SYMBOL-VALUE NIL 
  (Q-FASL-FETCH-SYMBOL-CELL 1))

(DEFUN Q-FASL-OP-FETCH-FUNCTION-CELL NIL 
  (Q-FASL-FETCH-SYMBOL-CELL 2))

(DEFUN Q-FASL-OP-FETCH-PROPERTY-CELL NIL 
  (Q-FASL-FETCH-SYMBOL-CELL 3))

(DEFUN Q-FASL-OP-END-OF-WHACK NIL 
  (SETQ FASL-RETURN-FLAG 'END-OF-WHACK)
  0)

(DEFUN Q-FASL-OP-END-OF-FILE NIL 
  (SETQ FASL-RETURN-FLAG 'EOF)
  0)

(DEFUN Q-FASL-OP-SOAK NIL 
  (PROG (COUNT)
	(SETQ COUNT (QFASL-NEXT-NIBBLE))
 L	(COND ((ZEROP COUNT) (RETURN (QFASL-GROUP T))))
	(M-FASL-NEXT-VALUE)
	(SETQ COUNT (1- COUNT))
	(GO L)))

(DEFUN Q-FASL-OP-SET-PARAMETER NIL 
  (PROG (FROM TO)
	(SETQ TO (M-FASL-NEXT-VALUE))
	(SETQ FROM (QFASL-GROUP T))
	(AS-1 (AR-1 FASL-TABLE FROM)
	       FASL-TABLE 
	       TO)
	(RETURN 0)))

(DEFUN Q-FASL-OP-FILE-PROPERTY-LIST NIL ;IGNORES IT
  (M-FASL-NEXT-VALUE)
  0)


(MAKUNBOUND 'Q-FASL-GROUP-DISPATCH) ;FLUSH OLD DISPATCH TABLE NOW THAT
				  ;NEW FUNCTIONS LOADED
