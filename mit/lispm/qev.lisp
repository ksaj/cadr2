;ARGUMENTS DESCRIPTIONS			;THIS IS THE -*-LISP-*- EVALUATOR.

;	** (c) Copyright 1980 Massachusetts Institute of Technology **

;THERE ARE 3 WAYS THE ARGUMENTS TO A FUNCTION CAN BE DESCRIBED:
;	1) "LAMBDA" LISTS - USED IN S-EXPRESSION S
;	2) ARGUMENT DESCRIPTION LISTS - USED IN MACRO-COMPILED CODE
;	3) "NUMERIC FORM" - USED FOR MICRO-CODE ENTRIES (BOTH "HAND" AND
;		MICRO-COMPILED) AND SWITCH-ARRAY S.

; THINGS TO BE SPECIFIED (OR DEFAULTED) ABOUT A VARIABLE.
;   1) "SPECIALNESS"
;	3 states: &LOCAL (FEF-LOCAL), &SPECIAL (FEF-SPECIAL) as in Maclisp,
;	and FEF-REMOTE which is decided by the compiler.
;   2) ARGUMENT SYNTAX.  POSSIBLITIES ARE REQUIRED ARG (FEF-ARG-REQ),
;	OPTIONAL ARG &OPTIONAL (FEF-ARG-OPT).  REST ARG &REST (FEF-ARG-REST),
;	AUX "ARG" &AUX	(FEF-ARG-AUX).  THIS LAST IS EXACTLY A "PROG VARIABLE"
;	REALLY AN ARGUMENT AT ALL.
;   3) QUOTE STATUS.  INFORMATION FOR THE CALLER AS TO WHETHER HE SHOULD
;	EVALUATE THE ARGUMENT BEFORE PASSING IT. (THIS IS ONE COMPONENT OF THE
;	DISTINCTION BETWEEN EXPR AND FEXPR IN MACLISP).  POSSIBILITIES ARE
;	&EVAL (FEF-QT-EVAL), &QUOTE (FEF-QT-QT), &QUOTE-DONTCARE (FEF-QT-DONTCARE).
;	FEF-QT-DONTCARE
;	SPECIFIES THE ABSENCE OF ERROR CHECKING, AND IS TAKEN TO BE EQUIVALENT TO
;	FEF-QT-EVAL OTHERWISE.  
;   4) DESIRED DATA TYPE.  IN MACRO-COMPILED CODE, THIS CAN PROVIDE ERROR CHECKING
;	WITH GREATER CONVENIENCE THAN EXPLICITLY PROGRAMMING A TYPE CHECK.  IN
;	MICRO-COMPILED CODE, GREATER EFFICENCY MAY BE OBTAINED IN COMPILED CODE,
;	PARTICULARILY AS A RESULT OF THE &FIXNUM DECLARATION.  AUTOMATIC RUN TIME
;	ERROR CHECKING OF THE SUPPLIED TYPE IS NOT DONE FOR MICRO-COMPILED FUNCTIONS.
;	POSSIBLE DATA TYPE DECLARATIONS ARE &DT-DONTCARE (THE NORMAL DEFAULT, 
;	FEF-DT-DONTCARE), &DT-NUMBER (FEF-DT-NUMBER), &DT-FIXNUM (23 BIT INTEGER, 
;	FEF-DT-FIXN), &DT-SYMBOL (FEF-DT-SYM), &ATOM (FEF-DT-ATOM), 
;	&LIST (FEF-DT-LIST), AND &DT-FRAME (FEF-DT-FRAME).

;THE LAMBDA LIST IS THE MOST GENERAL.  
; ELEMENTS OF THE LAMBDA LIST ARE OF THE FOLLOWING FORMS:
;   &DECLARATIONS -- ONE OF A GROUP OF RESERVED SYMBOLS STARTING WITH &.
;   SYMBOLIC ATOMS --  SPECIFYING A VARIABLE IN THE "CURRENT" MODE AS BUILT UP
;	FROM THE DECLARATIONS SEEN SO FAR. 
;   LISTS -- THE FIRST ELEMENT OF THE LIST IS THE VARIABLE NAME, AND
;       THE CADR IS THE INITIALIZATION.  VARIABLES OF TYPES FEF-ARG-OPT,
;       AND FEF-ARG-AUX MAY BE INITIALIZED.
; DECLARATIONS:
;   THE INITIAL STATE (ASSIGNED TO VARIABLES SEEN BEFORE ANY DECLARATIONS)
;   IS FEF-ARG-REQ, FEF-DT-DONTCARE, FEF-QT-DONTCARE AND FEF-LOCAL. 
;   THESE CAN BE CHANGED BY THE FOLLOWING DECLARATIONS:
;	&OPTIONAL &REST &AUX
;	&EVAL &QUOTE &QUOTE-DONTCARE 
;	&DT-DONTCARE &DT-NUMBER &DT-FIXNUM &DT-SYM &DT-ATOM
;		&DT-LIST &DT-FRAME
;	&SPECIAL &LOCAL  ALSO, A PARTICULAR VARIABLE WILL BE MADE SPECIAL
;		IF A SPECIAL PROPERTY IS FOUND ON ITS PROPERTY LIST, AS IN
;		MACLISP.

;THE SIMPLEST FORM OF ARGUMENT DESCRIPTION IS NUMERIC FORM.
;THE FUNCTION %ARGS-INFO WILL RETURN A NUMERIC FORM DESCRIPTION
;GIVEN ANY FUNCTION, HOWEVER BITS MAY BE SET INDICATING THAT THIS
;NUMERIC FORM DESCRIPTION DOES NOT TELL THE WHOLE STORY.
;NAME			VALUE		MEANING
;%ARG-DESC-QUOTED-REST	  10,,000000	HAS QUOTED REST ARGUMENT
;%ARG-DESC-EVALED-REST	  04,,000000	HAS EVALUATED REST ARGUMENT
;%ARG-DESC-FEF-QUOTE-HAIR 02,,000000	COMPLICATED FEF, CALLER MUST REFER TO
;					ARG DESC LIST FOR ARGUMENT EVAL/QUOTE INFO
;%ARG-DESC-INTERPRETED	  01,,000000	INTERPRETER TRAP, VALUE ALWAYS = 01000077
;%ARG-DESC-FEF-BIND-HAIR  00,,400000	COMPLICATED FEF, LINEAR ENTER MUST REFER TO
;					ARG DESC LIST
;%%ARG-DESC-MIN-ARGS	  00,,007700	MINIMUM NUMBER OF ARGUMENTS FIELD (COUNTING
;					REQUIRED ONLY)
;%%ARG-DESC-MAX-ARGS	  00,,000077	MAXIMUM NUMBER OF ARGUMENTS FIELD (COUNTING
;					REQUIRED AND OPTIONAL BUT NOT REST.)

; ARGUMENT DESCRIPTION LISTS OF MACRO-COMPILED FUNCTIONS.
;   EACH MACRO-COMPILED FUNCTION NORMALLY HAS AN ARGUMENT DESCRIPTION LIST (A-D-L),
;	WHICH HAS AN ENTRY FOR EVERY VARIABLE BOUND OR REFERENCED IN THE FUNCTION.
;	THE ENTRY CONSISTS OF:
;   1) A SINGLE Q HOLDING A FIXNUM WHICH HAS FIELDS DECODING ALL THE FEF-XX-YY
;	OPTIONS MENTIONED ABOVE.
;   2) OPTIONALLY, (AS SPECIFIED IN 1), ANOTHER Q WHICH HOLDS THE VARIABLE'S NAME.
;	THIS IS ONLY FOR DEBUGGING CONVENIENCE AND NEVER USED BY THE SYSTEM.
;   3) POSSIBLY ANOTHER Q SPECIFING INITIALIZING INFORMATION.  THIS IS REQUIRED
;	IN SOME CASES IF NON-NIL INITIALIZATION HAS BEEN SPECIFIED.  IN OTHER CASES
;	THE VARIABLE WILL BE INITIALIZED BY COMPILED CODE.
; ADDITIONALLY, IN THE FIXED ALLOCATED PART OF THE FEF, THERE ARE THE 
;   "FAST-OPTION-Q" AND THE "SPECIAL-VARIABLE-MAP" Q.  NORMALLY, THE INFORMATION
;    CONTAINED IN THESE QS IS REDUNDANT, AND THE PURPOSE IS SIMPLY TO SAVE PROCESSING
;    TIME SCANNING THRU THE A-D-L, IF POSSIBLE.  EACH OF THESE QS HAS
;    AND "OPTION" BIT,  WHICH IS TURNED OFF IF THE PARTICULAR FUNCTION 
;    DOES NOT CONFORM TO THE RESTRICTIONS NECESSARY TO PERMIT THE STORAGE OF THE
;    RELEVANT INFORMATION IN THE Q.  THESE QS ARE AUTOMATICALLY SET UP BY
;    QLAP FROM THE A-D-L.
; THE FAST ARGUMENT OPTION Q WILL BE STORED IN ANY CASE, BUT ONE OF THE
; %ARG-DESC-FEF-QUOTE-HAIR OR %ARG-DESC-FEF-BIND-HAIR
; BITS WILL BE ON IF IT DOESN'T INCLUDE ALL RELEVANT INFORMATION.
; THIS MAKES LIFE EASIER FOR THE %ARGS-INFO FUNCTION.
;
;  IF IT IS POSSIBLE TO EXPRESS THE A-D-L OF THE PARTICULAR FUNCTION
;    IN "NUMERIC FORM" (SEE BELOW), THIS IS DONE IN THE FAST-OPTION Q.  THIS THEN
;    SAVES THE MACRO-CODE FUNCTION ENTRY OPERATION FROM HAVING TO SCAN DOWN
;    THE A-D-L TO DETERMINE IF THERE ARE THE RIGHT # OF ARGS, RIGHT DATA-TYPES, ETC.
;    NOTE THAT THIS WILL NOT BE POSSIBLE IF NON-NIL VARIABLE INITIALIZATION
;    (NOT DONE BY COMPILED CODE) HAS BEEN USED.
;  THE SPECIAL-VARIABLE-MAP IS A BIT MAP, WITH BITS CORRESPONDING TO THOSE
;    POSITIONS IN THE PDL-FRAME THAT CORRESPOND TO SPECIAL VARIABLES.
;    THUS, DURING BINDING AND CONTEXT SWITCHING OPERATIONS, THE FRAME SWAPPER
;    CAN PROCEED DOWN THE S-V-TABLE (WHICH CONTAINS POINTER TO THE VALUE CELLS
;    OF SPECIAL VARIABLES) AND SWAP THE APPROPRIATE PDL-FRAME QS WITH THE CONTENTS
;    OF THE APPROPRIATE VALUE CELLS.  THE SPECIAL-VARIABLE-MAP Q CAN NOT BE USED
;    IF THERE ARE SPECIAL VARIABLES HIGHER IN THE FRAME THAN ADDRESSED BY THE
;    AVAILABLE BITS, OR IF THE FUNCTION HAS A REST ARG AND EITHER THE REST ARG
;    OR AN AUX ARG IS SPECIAL.  IN THE LATER CASE,  THE VARIABLE # OF ARGS
;    MAKES IT IMPOSSIBLE TO ASSIGN A STATIC CORRESPONDENCE BETWEEN PDL-FRAME
;    INDEXES AND SPECIAL VARIABLES.
;  IF BOTH THE FAST-OPTION-Q AND THE S-V-MAP Q ARE USABLE, IT IS POSSIBLE TO
;    DISPENSE WITH THE A-D-L ITSELF ENTIRELY, IF DESIRED, TO SAVE SPACE.  
;    THIS OPTION, IF SELECTED, CORRESPONDS TO THE "ABNORMAL" STATE IN THE
;    VARIOUS "NORMALLY,.. " QUALIFICATIONS ABOVE.

; "NUMERIC FORM" IS USED BY MICRO-COMPILED FUNCTIONS AND MICRO-SWITCH ARRAYS,
;	AND MESA FUNCTIONS.  (ALSO BY FAST ARG OPTION MACRO COMPILED FUNCTIONS.)
;	SEE THE DESCRIPTION OF %ARGS-INFO ABOVE FOR WHAT IS STORED IN THIS CASE.
;	THE DEFAULTING
;	OF &OPTIONAL VARIABLES AND VARIABLE INITIALIZATION IS DONE BY COMPILED CODE.
;	MICRO-COMPILED FUNCTIONS CAN NOT HAVE FEF-ARG-REST ARGS EXCEPT FOR THE FEXPR
;	CASE (AT LEAST FOR NOW.
;	ON THE REAL MACHINE, MAYBE). NO AUTOMATIC TYPE CHECKING IS EVER DONE,
;	SO IT MUST BE PROGRAMMED IF DESIRED.  HOWEVER, VARIABLES DECLARED OF TYPE
;	&FIXNUM CAN ACHIEVE SUBSTANTUAL SPEED EFFICIENCIES IN MANY CASES.
;	(NAMELY, ARITHMETIC OPERATIONS CAN BE COMPILED OPEN INSTEAD OF GOING
;	TO CLOSED SUBROUTINES).

;  A MICRO-SWITCH ARRAY IS A SINGLE DIMENSION ARRAY IN WHICH IS STORED POINTERS TO 
;	MICRO-COMPILED FUNCTIONS. 
;	THE SWITCH ARRAY HAS STORED IN IT AN NUMERIC ARGUMENT DESCRIPTION,
;	AND ALL FUNCTIONS IN THE ARRAY MUST BE CAPABLE OF HANDLING ARGUMENTS
;	AT LEAST AS THAT "GENERAL".  MICRO-SWITCH ARRAYS ARE EXTREMELY
;	EFFICIENT IN TIME.  RECOMMENDED USES ARE FOR DISPATCH TABLES
;	AND "LINKAGE BLOCKS".  THEY DON'T CURRENTLY EXIST.
	      
;EVAL.
;THE WAY THIS WORKS IS IT IS GIVEN A FORM.
;NON-LIST FORMS ARE EVALUATED APPROPRIATELY. (SIMPLE)
;IN THE CASE OF A LIST FORM, FIRST THE CAR IS TAKEN AND CONVERTED
;TO A KNOWN TYPE OF FUNCTIONAL OBJECT.  CERTAIN FUNCTIONS ARE
;SPECIAL-CASED.  THESE ARE:
;(MACRO . FCN)  APPLY THE FCN TO THE FORM BEING EVALED, THEN
;		START OVER USING THE RESULT AS THE FORM.
; SYMBOL	TAKE FUNCTION CELL CONTENTS AND USE THAT.
;
;OTHERWISE %ARGS-INFO IS CALLED
;ON THAT FUNCTION TO FIND OUT INFORMATION ABOUT THE ARGUMENTS.  IN THE
;CASE OF FEFS WITHOUT THE FAST ARG OPTION, THE A-D-L IS ALSO
;CONSULTED.  IN THE CASE OF INTERPRETED FUNCTIONS, THE LAMBDA LIST
;IS GROVELED OVER TO GET THE INFORMATION.  
;
; A CALL TO THE FUNCTIONAL OBJECT IS OPENED WITH %OPEN-CALL-BLOCK,
; THEN THE ARGUMENTS ARE GOBBLED DOWN, PROCESSED ACCORDING
; TO THE %ARGS-INFO, AND %PUSHED ONTO THE PDL.
; ONCE THE ARGUMENTS HAVE BEEN OBTAINED AND PUSHED,
; THE CALL IS MADE USING %ACTIVATE-OPEN-CALL-BLOCK.
; IN THE CASE OF AN ARRAY, A MACRO COMPILED FUNCTION, A MESA
; FUNCTION, A MICRO-COMPILED FUNCTION OR HAND MICRO-CODED FUNCTION,
; OR A STACK GROUP, THE MICRO CODED CALL ROUTINES WILL MAKE THE CALL.
; OTHERWISE, IT WILL TRAP BACK TO APPLY-LAMBDA:
; IF THE FUNCTION IS A LAMBDA-EXPRESSION IT WILL
; GROVEL OVER THE LAMBDA LIST AGAIN, BINDING THE LAMBDA-VARIABLES
; TO THE ARGUMENTS, THEN WILL EVALUATE THE BODY.
; OTHERWISE IF THE FUNCTION IS A LIST WHOSE CAR IS AUTOLOAD, 
; IT WILL ATTEMPT TO FASLOAD THAT FILE.  OTHERWISE IT WILL BARF.
;
; THE VALUES RETURNED BY THE INVOCATION OF THE FUNCTIONAL OBJECT
; ARE PASSED BACK TO THE CALLER OF EVAL AS FOLLOWS:
; ALL VALUES INCLUDING THE LAST ARE PASSED BACK BY VIRTUE OF AN INDIRECT
; POINTER IN THE ADDITIONAL INFORMATION CREATED BY %OPEN-CALL-BLOCK,
; IN THE CASE OF A MULTIPLE-VALUE TO CALL TO EVAL.
; THE LAST IS ALSO PASSED BACK BY THE FACT THAT THE DESTINATION SAVED
; BY %OPEN-CALL-BLOCK IS DESTINATION-RETURN, WHICH IS USEFUL MAINLY
; IN THE CASE OF A NON-MULTIPLE-VALUE CALL TO EVAL.
;
; NOTE THAT %ACTIVATE-OPEN-CALL-BLOCK
; MUST CHANGE THE CDR CODE OF THE LAST ARGUMENT STORED TO CDR-NIL,
; UNLESS THERE ARE NO ARGUMENTS.

; THE EVALHOOK FEATURE.
; THE FOLLOWING FUNCTION IS ALWAYS ON THE FUNCTION CELL OF '*EVAL'
; IT IS ALSO ON THE FUNCTION CELL OF 'EVAL', UNLESS THE EVALHOOK
; IS BEING USED, IN WHICH CASE THE LATTER CELL IS LAMBDA-BOUND TO SOMETHING ELSE.

; Note that *EVAL's first local is defined to be the number of the argument
; being evaluated, for backtracing purposes.

(DEFUN *EVAL (FORM)
   (PROG ((ARGNUM 0) FCTN CFCTN ARGL MAX-ARGS N-ARGS ARG-DESC
	  TEM ARG-TYPE QUOTE-STATUS ITEM NWADI
	  REST-FLAG LAMBDA-LIST SAVED-LAMBDA-LIST)

RETRY	(COND ((NUMBERP FORM) (RETURN FORM))
	      ((SYMBOLP FORM)
	       (RETURN
		(COND ((OR (BOUNDP FORM)
			   (AND (FBOUNDP 'TRAPPING-ENABLED-P) ;GO AHEAD AN REFERENCE IT
				(TRAPPING-ENABLED-P)))   ;TAKING TRAP TO REACH ERROR HANDLER
		       (SYMEVAL FORM))
		      (T (FERROR NIL "The variable ~S is unbound" FORM)))))
	      ((STRINGP FORM) (RETURN FORM))			;STRING SELF-EVALUATES
	      ((NOT (LISTP FORM))
	       ;; This RETURN would be MULTIPLE-VALUE-RETURN if that would compile.
	       (RETURN (CERROR T NIL ':INVALID-FORM
			       "~S is not a valid form" FORM))))
;;; Drops through.

;;; Drops through, when FORM is a combination.
LST	(SETQ FCTN (CAR FORM) ARGL (CDR FORM))
FRETRY
	(COND ((SYMBOLP FCTN)
	       (COND ((OR (FBOUNDP FCTN)
			  (AND (FBOUNDP 'TRAPPING-ENABLED-P)
			       (TRAPPING-ENABLED-P)))
		      (SETQ FCTN (FSYMEVAL FCTN)))
		     (T 
		      (FSET FCTN (CERROR T NIL ':UNDEFINED-FUNCTION
					 "The function ~S is undefined" FCTN))))
	       (GO FRETRY)))
	(SETQ CFCTN FCTN)
FCLOSED
	;; Come here when calling a closure, with the closure itself in FCTN
	;; and the closed function (with symbols traced already) in CFCTN.
	;; CFCTN is what to look at to decode the arguments.
	(SETQ ARG-DESC (%ARGS-INFO CFCTN))
	(OR (ZEROP (LOGAND %ARG-DESC-INTERPRETED ARG-DESC))
	    (GO INTERP))
	(SETQ MAX-ARGS (LDB %%ARG-DESC-MAX-ARGS ARG-DESC))
	(SETQ N-ARGS (LENGTH ARGL))
	(COND ((NOT (ZEROP (LOGAND %ARG-DESC-FEF-QUOTE-HAIR ARG-DESC)))
	       (GO FEF))				;FEF NOT FAST OPTION
	      ((NOT (ZEROP (LOGAND %ARG-DESC-QUOTED-REST ARG-DESC)))
	       (AND (> N-ARGS MAX-ARGS)
		    (GO FEXPR))))	;QUOTED REST ARG REALLY PRESENT

;HERE FOR SIMPLE CASE, ALL ARGUMENTS EVALUATED AND NO REST-ARG HAIR
;PUSH EVALUATED ARGUMENTS ON PDL AND CALL
SIMPLE	(%OPEN-CALL-BLOCK FCTN 0 4)
SIMPLE0	(%ASSURE-PDL-ROOM N-ARGS)
	(OR ARGL (GO CALL))
SIMPLE1	(SETQ ARGNUM (1+ ARGNUM))
	(%PUSH (EVAL (CAR ARGL)))
	(AND (SETQ ARGL (CDR ARGL))
	     (GO SIMPLE1))
CALL	(%ACTIVATE-OPEN-CALL-BLOCK)	;NEVER RETURNS SINCE CALL BLOCK HAS DEST RETURN

;HERE IN CASE THERE IS A QUOTED REST ARGUMENT, AND ALL OPTIONAL ARGS PRESENT.
;EVALUATE AND PUSH THE NORMAL ARGUMENTS, THEN PUSH THE REMAINING ARGUMENT LIST
FEXPR	(%ASSURE-PDL-ROOM (+ 2 MAX-ARGS))
	(%PUSH 0)
	(%PUSH 14000000)		;ADIFEX
	(%OPEN-CALL-BLOCK FCTN 1 4)	;OPEN CALL BLOCK, DEST RETURN
	(AND (= MAX-ARGS 0) (GO REST))
FEXPR1	(SETQ ARGNUM (1+ ARGNUM))
	(%PUSH (EVAL (CAR ARGL)))
	(SETQ ARGL (CDR ARGL))
	(AND (> (SETQ MAX-ARGS (1- MAX-ARGS)) 0) (GO FEXPR1))
REST	(%ASSURE-PDL-ROOM 1)
	(%PUSH ARGL)
	(%ACTIVATE-OPEN-CALL-BLOCK)	;NEVER RETURNS SINCE CALL BLOCK HAS DEST RETURN

;Here in case of a macro-compiled function with complicated arguments,
;therefore no fast-arg-option.  Push the evaluated or quoted arguments
;as indicated by the binding description list, then deal with the rest
;argument if any.
FEF	(COND ((AND (NOT (ZEROP (LOGAND %ARG-DESC-QUOTED-REST ARG-DESC)))
		    (> N-ARGS MAX-ARGS))		;QUOTED REST REALLY THERE,
		(%ASSURE-PDL-ROOM 2)			;SO CALL WITH FEXPR-CALL
		(%PUSH 0)
		(%PUSH 14000000)	;ADIFEX
		(SETQ NWADI 1))
	      ((SETQ NWADI 0)))
	(%OPEN-CALL-BLOCK FCTN NWADI 4)			;OPEN CALL BLOCK, DEST RETURN
	(SETQ ARG-DESC (GET-MACRO-ARG-DESC-POINTER CFCTN))	;GET BIND DESC LIST
FEFLP	(COND ((ATOM ARGL) 
	       (%ACTIVATE-OPEN-CALL-BLOCK)))	;NEVER RETURNS SINCE CALL BLOCK HAS DEST RETURN
	(SETQ ITEM (OR (CAR ARG-DESC) FEF-QT-EVAL))
	(COND ((NOT (ZEROP (LOGAND ITEM %FEF-NAME-PRESENT)))
		(SETQ ARG-DESC (CDR ARG-DESC))))
	(COND ((= (SETQ ARG-TYPE (LOGAND ITEM %FEF-ARG-SYNTAX))
		  FEF-ARG-OPT)
		(COND ((OR (= (SETQ TEM (LOGAND ITEM %FEF-INIT-OPTION))
			      FEF-INI-PNTR)
			   (= TEM FEF-INI-C-PNTR)
			   (= TEM FEF-INI-OPT-SA)
			   (= TEM FEF-INI-EFF-ADR))
			(SETQ ARG-DESC (CDR ARG-DESC)))))
	      ;; Time for a rest arg?  If evaled rest, eval and push remaining args.
	      ;; Otherwise, just push the list of remaining args.
	      ((= ARG-TYPE FEF-ARG-REST)
	       (AND (= (LOGAND ITEM %FEF-QUOTE-STATUS) FEF-QT-QT)
		    (GO REST))
	       (SETQ N-ARGS (LENGTH ARGL))
	       (GO SIMPLE0)))

;;; Process one more non-rest argument to the function, evalling if appropriate.
	(SETQ TEM (CAR ARGL))
	(SETQ ARGNUM (1+ ARGNUM))
	(OR (= (LOGAND ITEM %FEF-QUOTE-STATUS) FEF-QT-QT)
	    (SETQ TEM (EVAL TEM)))
	(%ASSURE-PDL-ROOM 1)
	(%PUSH TEM)
	(SETQ ARGL (CDR ARGL))
	(SETQ ARG-DESC (CDR ARG-DESC))
	(GO FEFLP)

;;; Come here when the function (in CFCTN) to be analyzed for arguments
;;; is not macro-compiled.  Check for macros, lambdas and closures.
INTERP	(SETQ TEM (%DATA-TYPE CFCTN))
	(COND ((LISTP CFCTN)
	       (COND ((OR (EQ (CAR CFCTN) 'LAMBDA)
			  (EQ (CAR CFCTN) 'NAMED-LAMBDA)
			  (EQ (CAR CFCTN) 'SUBST))
		      (GO LAMBDA))
		     ((AND (EQ FCTN CFCTN) (EQ (CAR CFCTN) 'MACRO))
		      (SETQ FORM (FUNCALL (CDR FCTN) FORM))
		      (GO RETRY))
		     ((OR (EQ (CAR CFCTN) 'CURRY-BEFORE) (EQ (CAR CFCTN) 'CURRY-AFTER))
		      (GO SIMPLE))))
	      ;; For calling a SELECT-METHOD, we can't figure out where it
	      ;; will dispatch to without evalling the args,
	      ;; so just assume all args should be evalled.
	      ((= TEM DTP-SELECT-METHOD)
	       (GO SIMPLE))
	      ((= TEM DTP-INSTANCE)	;Don't try to outwit instances
	       (GO SIMPLE))
	      ;; Closure => look at what it is a closure of,
	      ;; to determine what kind of arguments the closure requires.
	      ;; If the closure of a symbol, look at the definition of the symbol.
	      ;; An entity is just another type of closure.
	      ((OR (= TEM DTP-CLOSURE) (= TEM DTP-ENTITY))
	       (DO ((TEM1 (CAR (%MAKE-POINTER DTP-LIST CFCTN)) (FSYMEVAL TEM1)))
		   ((NOT (SYMBOLP TEM1))
		    (SETQ CFCTN TEM1)
		    (GO FCLOSED))))
	      ((AND (= TEM DTP-U-ENTRY)
		    (NOT (FIXP (SYSTEM:MICRO-CODE-ENTRY-AREA (%POINTER CFCTN)))))
	       (SETQ FCTN (SYSTEM:MICRO-CODE-ENTRY-AREA (%POINTER CFCTN)))
	       (GO FRETRY)))	  ;Not really microcoded now.
	(SETQ FCTN (CERROR T NIL ':INVALID-FUNCTION
			   "The function ~S has a function definition which is invalid"
			   (CAR FORM)))
	(GO FRETRY)

;;; Come here when calling a lambda-function (or a closure of one).
;;; Analyse the lambda list to determine which args to evaluate.
LAMBDA	(SETQ LAMBDA-LIST
	      (COND ((EQ (CAR CFCTN) 'NAMED-LAMBDA)
		     (CADDR CFCTN))
		    (T (CADR CFCTN))))	;FIRST PASS TO CHECK ON REST STUFF
	(SETQ SAVED-LAMBDA-LIST LAMBDA-LIST)	;SAVE FOR SECOND PASS.
	;; First, find out whether this function has a REST argument,
	;; and if so, whether it is evaluated.
	(SETQ QUOTE-STATUS '&EVAL)
	(SETQ NWADI 0)
LAMBP1	(COND ((OR (NULL LAMBDA-LIST) (EQ (CAR LAMBDA-LIST) '&AUX))
	       (GO LAMBP2))
	      ((MEMQ (CAR LAMBDA-LIST) 
		     '(&EVAL &QUOTE &QUOTE-DONTCARE))
	       (SETQ QUOTE-STATUS (CAR LAMBDA-LIST)))
	      ((EQ (CAR LAMBDA-LIST) '&REST)
	       (SETQ REST-FLAG T))
	      (REST-FLAG
		(COND ((NOT (MEMQ QUOTE-STATUS '(&EVAL &QUOTE-DONTCARE)))
		       ;; If the function has a quoted rest argument,
		       ;; we must call it with adi.
		       (%ASSURE-PDL-ROOM 2)
		       (%PUSH 0)
		       (%PUSH 14000000)			;ADIFEX
		       (SETQ NWADI 1)			;also used as flag at LAMBX1
		       (GO LAMBP2)))))
	(SETQ LAMBDA-LIST (CDR LAMBDA-LIST))
	(GO LAMBP1)

;;; Having pushed adi if there is a quoted rest argument,
;;; open the call block and push the arguments, evalling those that need it.
LAMBP2	(%OPEN-CALL-BLOCK FCTN NWADI 4)
	(SETQ LAMBDA-LIST SAVED-LAMBDA-LIST)
	(SETQ QUOTE-STATUS '&EVAL)
	(SETQ REST-FLAG NIL)
LAMBLP	(COND ((ATOM ARGL)
	       (COND ((= NWADI 1) (GO REST))
		     (T (GO CALL))))
	      ((EQ (CAR LAMBDA-LIST) '&AUX)
	       (SETQ LAMBDA-LIST NIL))
	      ((MEMQ (CAR LAMBDA-LIST) 
		     '(&EVAL &QUOTE &QUOTE-DONTCARE))
	       (SETQ QUOTE-STATUS (CAR LAMBDA-LIST))
	       (GO LAMBL1))
	      ((EQ (CAR LAMBDA-LIST) '&REST)
	       (SETQ REST-FLAG T)
	       (GO LAMBL1))
	      ((MEMQ (CAR LAMBDA-LIST) LAMBDA-LIST-KEYWORDS) (GO LAMBL1)))
	;; Here if next thing in lambda list is a variable, not a keyword.
	;; Now we know whether the argument needs to be evaluated, etc.
	(AND REST-FLAG (GO LAMBRST))
	(SETQ TEM (CAR ARGL))			;ORDINARY VARIABLE
	(SETQ ARGNUM (1+ ARGNUM))
	(OR (AND LAMBDA-LIST (EQ QUOTE-STATUS '&QUOTE))
	    (SETQ TEM (EVAL TEM)))
	(%ASSURE-PDL-ROOM 1)
	(%PUSH TEM)
	(SETQ ARGL (CDR ARGL))
LAMBL1	(SETQ LAMBDA-LIST (CDR LAMBDA-LIST))
	(GO LAMBLP)

LAMBRST	(COND ((EQ QUOTE-STATUS '&QUOTE) (GO REST))
	      (T
	       (SETQ N-ARGS (LENGTH ARGL))
	       (GO SIMPLE0)))
))

(DEFUN EVALHOOK (FORM EVALHOOK) ;EVALHOOK IS &SPECIAL
  (BIND (FUNCTION-CELL-LOCATION 'EVAL) (FUNCTION EVALHOOK1))
  (*EVAL FORM))

;STANDIN FOR EVAL.
(DEFUN EVALHOOK1 (FORM &AUX TEM)
  (SETQ TEM (IF (AND (BOUNDP 'EVALHOOK) (NOT (NULL EVALHOOK)))
		EVALHOOK
		#'*EVAL))
  (BIND (VALUE-CELL-LOCATION 'EVALHOOK) NIL)
  (FUNCALL TEM FORM))

;UCODE INTERPRETER TRAP COMES HERE
;NOTE WILL NEVER BE CALLED BY FEXPR-CALL OR LEXPR-CALL, INSTEAD UCODE
;WILL PSEUDO-SPREAD THE REST-ARGUMENT-LIST BY HACKING THE CDR CODES.

;AUTOLOAD HERE CAN'T WIN BECAUSE IT DOESNT KNOW WHAT TO REEVALUATE.
; PUT IT INTO EVAL?

(DEFUN APPLY-LAMBDA (FCTN A-VALUE-LIST)
    (PROG APPLY-LAMBDA (TEM)
       (OR (LISTP FCTN) (GO BAD-FUNCTION))
       TAIL-RECURSE
       (COND ((EQ (CAR FCTN) 'CURRY-AFTER)
	      (PROG ()
		  (SETQ TEM (CDDR FCTN))
		  (%OPEN-CALL-BLOCK (CADR FCTN) 0 4)
		  (%ASSURE-PDL-ROOM (+ (LENGTH TEM) (LENGTH A-VALUE-LIST)))
		  LOOP1
		  (OR A-VALUE-LIST (GO LOOP2))
		  (%PUSH (CAR A-VALUE-LIST))
		  (AND (SETQ A-VALUE-LIST (CDR A-VALUE-LIST))
		       (GO LOOP1))

		  LOOP2
		  (OR TEM (GO DONE))
		  (%PUSH (EVAL (CAR TEM)))
		  (AND (SETQ TEM (CDR TEM))
		       (GO LOOP2))

		  DONE
		  (%ACTIVATE-OPEN-CALL-BLOCK)))
	     ((EQ (CAR FCTN) 'CURRY-BEFORE)
	      (PROG ()
		  (SETQ TEM (CDDR FCTN))
		  (%OPEN-CALL-BLOCK (CADR FCTN) 0 4)
		  (%ASSURE-PDL-ROOM (+ (LENGTH TEM) (LENGTH A-VALUE-LIST)))
		  LOOP1
		  (OR TEM (GO LOOP2))
		  (%PUSH (EVAL (CAR TEM)))
		  (AND (SETQ TEM (CDR TEM))
		       (GO LOOP1))

		  LOOP2
		  (OR A-VALUE-LIST (GO DONE))
		  (%PUSH (CAR A-VALUE-LIST))
		  (AND (SETQ A-VALUE-LIST (CDR A-VALUE-LIST))
		       (GO LOOP2))

		  DONE
		  (%ACTIVATE-OPEN-CALL-BLOCK)))
	     ((OR (EQ (CAR FCTN) 'LAMBDA)
                  (EQ (CAR FCTN) 'SUBST)
		  (EQ (CAR FCTN) 'NAMED-LAMBDA))
	      (PROG* (OPTIONALF TEM RESTF INIT
				(FCTN (COND ((EQ (CAR FCTN) 'NAMED-LAMBDA) (CDR FCTN))
					    (T FCTN)))
				(LAMBDA-LIST (CADR FCTN))
				(LOCAL-DECLARATIONS LOCAL-DECLARATIONS)
				(DT-STATUS '&DT-DONTCARE)
				(VALUE-LIST A-VALUE-LIST))
		     (SETQ FCTN (CDDR FCTN))	;throw away lambda list
		     (AND (CDR FCTN) (STRINGP (CAR FCTN)) (POP FCTN))	;and doc string.
		     ;; Process any (DECLARE) at the front of the function.
		     ;; This does not matter for SPECIAL declarations,
		     ;; but for MACRO declarations it might be important
		     ;; even in interpreted code.
		     (AND (NOT (ATOM (CAR FCTN)))
			  (EQ (CAAR FCTN) 'DECLARE)
			  (SETQ LOCAL-DECLARATIONS (APPEND (CDAR FCTN) LOCAL-DECLARATIONS)))
		L    (COND ((NULL VALUE-LIST) (GO LP1))
			   ((OR (NULL LAMBDA-LIST)
				(EQ (CAR LAMBDA-LIST) '&AUX)) 
			    (GO TOO-MANY-ARGS))
			   ((EQ (CAR LAMBDA-LIST) '&OPTIONAL)
			    (SETQ OPTIONALF T)
			    (GO L1))		    ;Do next value.
			   ((EQ (CAR LAMBDA-LIST) '&REST)
			    (SETQ RESTF T)
			    (GO L1))		    ;Do next value.
			   
			   ((MEMQ (CAR LAMBDA-LIST)
				  '(&DT-DONTCARE &DT-NUMBER &DT-FIXNUM &DT-SYMBOL &DT-ATOM 
						 &DT-LIST &DT-FRAME))
			    (SETQ DT-STATUS (CAR LAMBDA-LIST))
			    (GO L1))		    ;Do next value.
			   ((MEMQ (CAR LAMBDA-LIST) LAMBDA-LIST-KEYWORDS)
			    (GO L1))
			   ((ATOM (CAR LAMBDA-LIST)) (SETQ TEM (CAR LAMBDA-LIST)))
			   ((ATOM (CAAR LAMBDA-LIST))
			    (SETQ TEM (CAAR LAMBDA-LIST))
			    ;; If it's &OPTIONAL (FOO NIL FOOP),
			    ;; bind FOOP to T since FOO was specified.
			    (COND ((AND OPTIONALF (CDDAR LAMBDA-LIST))
				   (AND (NULL (CADDAR LAMBDA-LIST)) (GO BAD-LAMBDA-LIST))
				   (BIND (VALUE-CELL-LOCATION (CADDAR LAMBDA-LIST)) T))))
			   (T (GO BAD-LAMBDA-LIST)))
		     ; Get here if there was a real value in (CAR LAMBDA-LIST).  It is in TEM.
		     (COND (RESTF (SETQ INIT VALUE-LIST)
				  (GO LP3)))
		     (AND (NULL TEM) (GO BAD-LAMBDA-LIST))
		     (BIND (VALUE-CELL-LOCATION TEM) (CAR VALUE-LIST))
		     (SETQ VALUE-LIST (CDR VALUE-LIST))
		L1   (SETQ LAMBDA-LIST (CDR LAMBDA-LIST))
		     (GO L)
		     
	        LP1  (COND ((NULL LAMBDA-LIST) (GO EX1)) ;HERE AFTER VALUES ARE USED UP.
			   ((MEMQ (CAR LAMBDA-LIST) '(&OPTIONAL &REST &AUX))
			    (SETQ OPTIONALF T)		;SUPPRESS TOO FEW ARGS ERROR
			    (GO LP2))
			   ((MEMQ (CAR LAMBDA-LIST) LAMBDA-LIST-KEYWORDS)
			    (GO LP2))
			   ((AND (NULL OPTIONALF) (NULL RESTF))
			    (GO TOO-FEW-ARGS))
			   ((ATOM (CAR LAMBDA-LIST)) (SETQ TEM (CAR LAMBDA-LIST))
			    (SETQ INIT NIL))
			   ((ATOM (CAAR LAMBDA-LIST))
			    (SETQ TEM (CAAR LAMBDA-LIST))
			    (SETQ INIT (EVAL (CADAR LAMBDA-LIST)))
			    ;; For (FOO NIL FOOP), bind FOOP to NIL since FOO is missing.
			    (COND ((CDDAR LAMBDA-LIST)
				   (AND (NULL (CADDAR LAMBDA-LIST)) (GO BAD-LAMBDA-LIST))
				   (BIND (VALUE-CELL-LOCATION (CADDAR LAMBDA-LIST)) NIL))))
			   (T (GO BAD-LAMBDA-LIST)))
		LP3  (AND (NULL TEM) (GO BAD-LAMBDA-LIST))
		     (BIND (VALUE-CELL-LOCATION TEM) INIT)
		LP2  (SETQ LAMBDA-LIST (CDR LAMBDA-LIST))
		     (GO LP1)
		     
		EX1  (DO ((L FCTN (CDR L)))
			 ((NULL (CDR L))
			  (RETURN-FROM APPLY-LAMBDA
				       (MULTIPLE-VALUE-RETURN (EVAL (CAR L)))))
		       (EVAL (CAR L)))))
             ;; *** Who put this in and what could they possibly imagine it does? ***
	     ;; ANSWER: I not only imagined, but verified,
	     ;; that this makes it possible to apply a macro
	     ;; in a way that works reasonably if the macro "evals its args".
	     ;;*** Yes, but it completely shafts you to the wall in the usual case ***
	     ((EQ (CAR FCTN) 'MACRO)
              (CERROR T NIL NIL
		      "Funcalling the macro ~S - type c-C to attempt to kludge it via EVAL"
		      (EH:FUNCTION-NAME (CDR FCTN)))
	      (MULTIPLE-VALUE-RETURN
                   (EVAL (CONS FCTN (MAPCAR (FUNCTION (LAMBDA (ARG) `',ARG))
                                            A-VALUE-LIST)))))
	     )
       BAD-FUNCTION
       ;; COND can drop through to here for a totally unrecognized function.
       (SETQ FCTN
	     (CERROR T NIL ':INVALID-FUNCTION
		     "~S is an invalid function" FCTN))
       (GO RETRY)

       ;; Errors jump out of the inner PROG to unbind any lambda-vars bound with BIND.

       BAD-LAMBDA-LIST
       (SETQ FCTN
	     (CERROR T NIL ':INVALID-FUNCTION
		     "~S has an invalid LAMBDA list" FCTN))
       RETRY
       (AND (LISTP FCTN) (GO TAIL-RECURSE))
       (MULTIPLE-VALUE-RETURN
	 (APPLY FCTN A-VALUE-LIST))

       TOO-FEW-ARGS
       (MULTIPLE-VALUE-RETURN 
	 (CERROR T NIL ':WRONG-NUMBER-OF-ARGUMENTS
		 "Function ~S called with only ~D argument~1G~P"
		 FCTN (LENGTH A-VALUE-LIST)))

       TOO-MANY-ARGS
       (MULTIPLE-VALUE-RETURN
	 (CERROR T NIL ':WRONG-NUMBER-OF-ARGUMENTS
		 "Function ~S given too many arguments (~D)"
		 FCTN (LENGTH A-VALUE-LIST)))))

(DEFPROP :INVALID-FUNCTION INVALID-FUNCTION-EH-PROCEED EH:PROCEED)
(DEFUN INVALID-FUNCTION-EH-PROCEED (IGNORE IGNORE)
  (EH:READ-OBJECT "Form to evaluate and use as replacement function"))

(DEFPROP :WRONG-NUMBER-OF-ARGUMENTS INVALID-FORM-EH-PROCEED EH:PROCEED)
(DEFPROP :INVALID-FORM INVALID-FORM-EH-PROCEED EH:PROCEED)
(DEFUN INVALID-FORM-EH-PROCEED (IGNORE IGNORE)
  (EH:READ-OBJECT "Form to evaluate instead"))

;;;FULL MAPPING FUNCTIONS

(DEFUN MAPCAR (FCN &EVAL &REST LISTS)
  (PROG (V P LP)
	(SETQ P (VALUE-CELL-LOCATION 'V))		;ACCUMULATE LIST IN P, V
	(%ASSURE-PDL-ROOM (+ 4 (LENGTH LISTS)))		;MAKE SURE %PUSH'S DON'T LOSE
   L	(SETQ LP LISTS)					;PICK UP NEXT ELEMENT OF EACH LIST
	(%OPEN-CALL-BLOCK FCN 0 1)			;DESTINATION STACK
   L1	(OR LP (GO L2))					;ALL LISTS PICKED UP
	(AND (NULL (CAR LP)) (RETURN V))		;A LIST ENDS, RETURN
	(%PUSH (CAAR LP))				;PASS CAR OF THIS LIST AS ARG
	(RPLACA LP (CDAR LP))				;ADVANCE TO CDR OF THIS LIST
	(SETQ LP (CDR LP))				;DO NEXT LIST
	(GO L1)
   L2	(%ACTIVATE-OPEN-CALL-BLOCK)			;MAKE THE CALL
	(SETQ LP (%POP))				;GRAB RESULT BEFORE PDL CHANGES
	(RPLACD P (SETQ P (NCONS LP)))			;CONS IT ONTO LIST
	(GO L)))

(DEFUN MAPC (FCN &EVAL &REST LISTS)
  (PROG (LP RES)
	(SETQ RES (CAR LISTS))				;RESULT WILL BE FIRST ARG
	(%ASSURE-PDL-ROOM (+ 4 (LENGTH LISTS)))		;MAKE SURE %PUSH'S DON'T LOSE
   L	(SETQ LP LISTS)					;PICK UP NEXT ELEMENT OF EACH LIST
	(%OPEN-CALL-BLOCK FCN 0 0)			;DESTINATION IGNORE
   L1	(OR LP (GO L2))					;ALL LISTS PICKED UP
	(AND (NULL (CAR LP)) (RETURN RES))		;A LIST ENDS, RETURN SECOND ARG
	(%PUSH (CAAR LP))				;PASS CAR OF THIS LIST AS ARG
	(RPLACA LP (CDAR LP))				;ADVANCE TO CDR OF THIS LIST
	(SETQ LP (CDR LP))				;DO NEXT LIST
	(GO L1)
   L2	(%ACTIVATE-OPEN-CALL-BLOCK)			;MAKE THE CALL
	(GO L)))

(DEFUN MAPLIST (FCN &EVAL &REST LISTS)
  (PROG (V P LP)
	(SETQ P (VALUE-CELL-LOCATION 'V))		;ACCUMULATE LIST IN P, V
	(%ASSURE-PDL-ROOM (+ 4 (LENGTH LISTS)))		;MAKE SURE %PUSH'S DON'T LOSE
   L	(SETQ LP LISTS)					;PICK UP NEXT ELEMENT OF EACH LIST
	(%OPEN-CALL-BLOCK FCN 0 1)			;DESTINATION STACK
   L1	(OR LP (GO L2))					;ALL LISTS PICKED UP
	(AND (NULL (CAR LP)) (RETURN V))		;A LIST ENDS, RETURN
	(%PUSH (CAR LP))				;PASS THIS LIST AS ARG
	(RPLACA LP (CDAR LP))				;ADVANCE TO CDR OF THIS LIST
	(SETQ LP (CDR LP))				;DO NEXT LIST
	(GO L1)
   L2	(%ACTIVATE-OPEN-CALL-BLOCK)			;MAKE THE CALL
	(SETQ LP (%POP))				;GRAB RESULT BEFORE PDL CHANGES
	(RPLACD P (SETQ P (NCONS LP)))			;CONS IT ONTO LIST
	(GO L)))

(DEFUN MAP (FCN &EVAL &REST LISTS)
  (PROG (LP RES)
	(SETQ RES (CAR LISTS))				;RESULT WILL BE FIRST ARG
	(%ASSURE-PDL-ROOM (+ 4 (LENGTH LISTS)))		;MAKE SURE %PUSH'S DON'T LOSE
   L	(SETQ LP LISTS)					;PICK UP NEXT ELEMENT OF EACH LIST
	(%OPEN-CALL-BLOCK FCN 0 0)			;DESTINATION IGNORE
   L1	(OR LP (GO L2))					;ALL LISTS PICKED UP
	(AND (NULL (CAR LP)) (RETURN RES))		;A LIST ENDS, RETURN SECOND ARG
	(%PUSH (CAR LP))				;PASS THIS LIST AS ARG
	(RPLACA LP (CDAR LP))				;ADVANCE TO CDR OF THIS LIST
	(SETQ LP (CDR LP))				;DO NEXT LIST
	(GO L1)
   L2	(%ACTIVATE-OPEN-CALL-BLOCK)			;MAKE THE CALL
	(GO L)))

(DEFUN MAPCAN (FCN &EVAL &REST LISTS)
  (PROG (V P LP)
	(SETQ P (VALUE-CELL-LOCATION 'V))		;ACCUMULATE LIST IN P, V
	(%ASSURE-PDL-ROOM (+ 4 (LENGTH LISTS)))		;MAKE SURE %PUSH'S DON'T LOSE
   L	(SETQ LP LISTS)					;PICK UP NEXT ELEMENT OF EACH LIST
	(%OPEN-CALL-BLOCK FCN 0 1)			;DESTINATION STACK
   L1	(OR LP (GO L2))					;ALL LISTS PICKED UP
	(AND (NULL (CAR LP)) (RETURN V))		;A LIST ENDS, RETURN
	(%PUSH (CAAR LP))				;PASS CAR OF THIS LIST AS ARG
	(RPLACA LP (CDAR LP))				;ADVANCE TO CDR OF THIS LIST
	(SETQ LP (CDR LP))				;DO NEXT LIST
	(GO L1)
   L2	(%ACTIVATE-OPEN-CALL-BLOCK)			;MAKE THE CALL
	(SETQ LP (%POP))				;GRAB RESULT BEFORE PDL CHANGES
	(AND (ATOM LP) (GO L))				;IF NOT A LIST, IGNORE IT
	(RPLACD P LP)					;CONC IT ONTO LIST
	(SETQ P (LAST LP))				;SAVE NEW CELL TO BE CONC'ED ONTO
	(GO L)))

(DEFUN MAPCON (FCN &EVAL &REST LISTS)
  (PROG (V P LP)
	(SETQ P (VALUE-CELL-LOCATION 'V))		;ACCUMULATE LIST IN P, V
	(%ASSURE-PDL-ROOM (+ 4 (LENGTH LISTS)))		;MAKE SURE %PUSH'S DON'T LOSE
   L	(SETQ LP LISTS)					;PICK UP NEXT ELEMENT OF EACH LIST
	(%OPEN-CALL-BLOCK FCN 0 1)			;DESTINATION STACK
   L1	(OR LP (GO L2))					;ALL LISTS PICKED UP
	(AND (NULL (CAR LP)) (RETURN V))		;A LIST ENDS, RETURN
	(%PUSH (CAR LP))				;PASS THIS LIST AS ARG
	(RPLACA LP (CDAR LP))				;ADVANCE TO CDR OF THIS LIST
	(SETQ LP (CDR LP))				;DO NEXT LIST
	(GO L1)
   L2	(%ACTIVATE-OPEN-CALL-BLOCK)			;MAKE THE CALL
	(SETQ LP (%POP))				;GRAB RESULT BEFORE PDL CHANGES
	(AND (ATOM LP) (GO L))				;IF NOT A LIST, IGNORE IT
	(RPLACD P LP)					;CONC IT ONTO LIST
	(SETQ P (LAST LP))				;SAVE NEW CELL TO BE CONC'ED ONTO
	(GO L)))

(DEFUN FUNCALL (FN &EVAL &REST ARGS)
  (APPLY FN ARGS))

(DEFUN QUOTE (&QUOTE X) X)

(DEFUN FUNCTION (&QUOTE X)
	(COND ((SYMBOLP X)
	       (OR (FBOUNDP X) (FERROR NIL "The function ~S is not defined" X))
	       (CDR (FUNCTION-CELL-LOCATION X)))
	      (T X)))

(DEFUN FUNCTIONAL-ALIST (&QUOTE X)   ;JUST LIKE QUOTE INTERPRETED.  HOWEVER, THE COMPILER
       X)     ;IS TIPPED OFF TO BREAK OFF  AND COMPILE SEPARATELY FUNCTIONS WHICH APPEAR
	      ;IN THE CDR POSITION OF AN ALIST ELEMENT

;; Return a list of all elements of LIST for which PRED is true.
;; If extra args are supplied, their successive elements are passed
;; to PRED along with elements of LIST.  Unlike MAP, etc., we process
;; every element of LIST even if extra args are exhausted by cdr'ing.
(DEFUN SUBSET (PRED LIST &REST EXTRA-LISTS &AUX VALUE)
  (DO ((VALUE-PTR (VALUE-CELL-LOCATION 'VALUE))
       (L LIST (CDR L)))
      ((NULL L) VALUE)
    (%OPEN-CALL-BLOCK PRED 0 1)
    (%PUSH (CAR L))
    (DO ((EX EXTRA-LISTS (CDR EX))) ((NULL EX))
      (%PUSH (CAAR EX))
      (RPLACA EX (CDAR EX)))
    (%ACTIVATE-OPEN-CALL-BLOCK)
    (AND (%POP)
	 (RPLACD VALUE-PTR (SETQ VALUE-PTR (CONS (CAR L) NIL))))))

;; Like SUBSET but negates the predicate.
(DEFUN SUBSET-NOT (PRED LIST &REST EXTRA-LISTS &AUX VALUE)
  (DO ((VALUE-PTR (VALUE-CELL-LOCATION 'VALUE))
       (L LIST (CDR L)))
      ((NULL L) VALUE)
    (%OPEN-CALL-BLOCK PRED 0 1)
    (%PUSH (CAR L))
    (DO ((EX EXTRA-LISTS (CDR EX))) ((NULL EX))
      (%PUSH (CAAR EX))
      (RPLACA EX (CDAR EX)))
    (%ACTIVATE-OPEN-CALL-BLOCK)
    (OR (%POP)
	(RPLACD VALUE-PTR (SETQ VALUE-PTR (CONS (CAR L) NIL))))))

    
