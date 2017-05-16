" Vim syntax file
"    Language: Oracle Procedural SQL (PL/SQL)
"  Maintainer: Jeff Lanzarotta (frizbeefanatic@yahoo.com)
"         URL: http://lanzarotta.tripod.com/vim/syntax/plsql.vim.zip
" Last Change: April 30, 2001
"
" Alt Version: 23 July 2001, Austin Ziegler (austin@halostatue.ca)
"         URL: http://www.halostatue.ca/vim/syntax/plsql.vim
"       Notes: Now includes 8i+ features.
"
" TODO Coordinate with Mr Lanzarotta on incorporating the changes noted here,
" possibly renaming activation variables (e.g., the C based ones).
"
" Alt Version: 16 Sept 2002, Geoff Evans and Bill Pribyl (bill@plnet.org)
" Last Change: Mon June 10 09:27:18 CDT 2002
"         URL: http://plnet.org/files/vim/
"       Notes: Includes some additional 9i keywords.


    " For version 5.x, clear all syntax items.
    " For version 6.x, quit when a syntax file was already loaded.

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif


    " Todo.
    " 20010723az: moved syn case igngore to after the plsqlTodo stuff...

syn keyword plsqlTodo TODO FIXME XXX DEBUG NOTE

    " plsqlCommentGroup allows adding matches for special things in comments
    " 20010723az: Added this so that these could be matched in comments...

syn cluster plsqlCommentGroup contains=plsqlTodo

syn case ignore

syn match   plsqlGarbage        "[^ \t()]"
syn match   plsqlIdentifier     "[a-z][a-z0-9$_#]*"
syn match   plsqlHostIdentifier ":[a-z][a-z0-9$_#]*"


    " 20010723az: When wanted, highlight the trailing whitespace -- this is
    " based on c_space_errors

if exists("c_space_errors")
    if !exists("c_no_trail_space_error")
        syn match plsqlSpaceError "\s\+$"
    endif
    if !exists("c_no_tab_space_error")
        syn match plsqlSpaceError " \+\t"me=e-1
    endif
endif


    " Symbols.

syn match   plsqlSymbol         "\(;\|,\|\.\)"


    " Operators.

syn match   plsqlOperator       "\(+\|-\|\*\|/\|=\|<\|>\|@\|\*\*\|!=\|\~=\)"
syn match   plsqlOperator       "\(^=\|<=\|>=\|:=\|=>\|\.\.\|||\|<<\|>>\|\"\)"


    " Some of Oracle's SQL keywords.

syn keyword plsqlSQLKeyword ABORT ACCESS ACCESSED ADD AFTER ALL ALTER AND ANY
syn keyword plsqlSQLKeyword AS ASC ATTRIBUTE AUDIT AUTHORIZATION AVG BASE_TABLE
syn keyword plsqlSQLKeyword BEFORE BETWEEN BY CASCADE CAST CHECK CLUSTER
syn keyword plsqlSQLKeyword CLUSTERS COLAUTH COLUMN COMMENT COMPRESS CONNECT
syn keyword plsqlSQLKeyword CONSTRAINT CRASH CREATE CURRENT DATA DATABASE
syn keyword plsqlSQLKeyword DATA_BASE DBA DEFAULT DELAY DELETE DESC DISTINCT
syn keyword plsqlSQLKeyword DROP DUAL ELSE EXCLUSIVE EXISTS EXTENDS EXTRACT
syn keyword plsqlSQLKeyword FILE FORCE FOREIGN FROM GRANT GROUP HAVING HEAP
syn keyword plsqlSQLKeyword IDENTIFIED IDENTIFIER IMMEDIATE IN INCLUDING
syn keyword plsqlSQLKeyword INCREMENT INDEX INDEXES INITIAL INSERT INSTEAD
syn keyword plsqlSQLKeyword INTERSECT INTO INVALIDATE IS ISOLATION KEY LIBRARY
syn keyword plsqlSQLKeyword LIKE LOCK MAXEXTENTS MINUS MODE MODIFY MULTISET
syn keyword plsqlSQLKeyword NESTED NOAUDIT NOCOMPRESS NOT NOWAIT OF OFF OFFLINE
syn keyword plsqlSQLKeyword ON ONLINE OPERATOR OPTION OR ORDER ORGANIZATION
syn keyword plsqlSQLKeyword PCTFREE PRIMARY PRIOR PRIVATE PRIVILEGES PUBLIC
syn keyword plsqlSQLKeyword QUOTA RELEASE RENAME REPLACE RESOURCE REVOKE ROLLBACK
syn keyword plsqlSQLKeyword ROW ROWLABEL ROWS SCHEMA SELECT SEPARATE SESSION SET
syn keyword plsqlSQLKeyword SHARE SIZE SPACE START STORE SUCCESSFUL SYNONYM
syn keyword plsqlSQLKeyword SYSDATE TABLE TABLES TABLESPACE TEMPORARY TO TREAT
syn keyword plsqlSQLKeyword TRIGGER TRUNCATE UID UNION UNIQUE UNLIMITED UPDATE
syn keyword plsqlSQLKeyword USE USER VALIDATE VALUES VIEW WHENEVER WHERE WITH


    " PL/SQL's own keywords
    " bp: Including external procedure mapping keywords here; you may disagree

syn keyword plsqlKeyword AGENT AND ANY ARRAY ASSIGN AS AT AUTHID BEGIN BODY BY
syn keyword plsqlKeyword BULK C CASE CHAR_BASE CLOSE COLLECT CONSTANT
syn keyword plsqlKeyword CONSTRUCTOR CONTEXT CURRVAL DECLARE DVOID EXCEPTION
syn keyword plsqlKeyword EXCEPTION_INIT EXECUTE EXIT FETCH FINAL FUNCTION
syn keyword plsqlKeyword GOTO HASH IMMEDIATE IN INDICATOR INSTANTIABLE IS
syn keyword plsqlKeyword JAVA LANGUAGE LIBRARY MAP MEMBER NAME NEW NOCOPY
syn keyword plsqlKeyword NUMBER_BASE OBJECT OCICOLL OCIDATE OCIDATETIME
syn keyword plsqlKeyword OCILOBLOCATOR OCINUMBER OCIRAW OCISTRING OF OPAQUE
syn keyword plsqlKeyword OPEN OR ORDER OTHERS OUT OVERRIDING PACKAGE
syn keyword plsqlKeyword PARALLEL_ENABLE PARAMETERS PARTITION PIPELINED PRAGMA
syn keyword plsqlKeyword PROCEDURE RAISE RANGE REF RESULT RETURN REVERSE ROWTYPE
syn keyword plsqlKeyword SB1 SELF SHORT SIZE_T SQL SQLCODE SQLERRM STATIC
syn keyword plsqlKeyword SUBTYPE TDO THEN TABLE TIMEZONE_ABBR TIMEZONE_HOUR
syn keyword plsqlKeyword TIMEZONE_MINUTE TIMEZONE_REGION TYPE UNDER UNSIGNED
syn keyword plsqlKeyword USING VARIANCE VARRAY VARYING WHEN WRITE
syn match   plsqlKeyword "\<END\>"
syn match   plsqlKeyword "\.COUNT\>"hs=s+1
syn match   plsqlKeyword "\.EXISTS\>"hs=s+1
syn match   plsqlKeyword "\.FIRST\>"hs=s+1
syn match   plsqlKeyword "\.LAST\>"hs=s+1
syn match   plsqlKeyword "\.DELETE\>"hs=s+1
syn match   plsqlKeyword "\.PREV\>"hs=s+1
syn match   plsqlKeyword "\.NEXT\>"hs=s+1


    " PL/SQL functions.

syn keyword plsqlFunction ABS ACOS ADD_MONTHS ASCII ASCIISTR ASIN ATAN ATAN2
syn keyword plsqlFunction BFILENAME BITAND CEIL CHARTOROWID CHR COALESCE
syn keyword plsqlFunction COMMIT COMMIT_CM COMPOSE CONCAT  CONVERT  COS COSH
syn keyword plsqlFunction COUNT CUBE CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP
syn keyword plsqlFunction DBTIMEZONE DECODE DECOMPOSE DEREF DUMP EMPTY_BLOB
syn keyword plsqlFunction EMPTY_CLOB EXISTS EXP FLOOR FROM_TZ GETBND GLB
syn keyword plsqlFunction GREATEST GREATEST_LB GROUPING HEXTORAW  INITCAP
syn keyword plsqlFunction INSTR INSTR2 INSTR4 INSTRB INSTRC ISNCHAR LAST_DAY
syn keyword plsqlFunction LEAST LEAST_UB LENGTH LENGTH2 LENGTH4 LENGTHB LENGTHC
syn keyword plsqlFunction LN LOCALTIME LOCALTIMESTAMP LOG LOWER LPAD
syn keyword plsqlFunction LTRIM LUB MAKE_REF MAX MIN MOD MONTHS_BETWEEN
syn keyword plsqlFunction NCHARTOROWID NCHR NEW_TIME NEXT_DAY NHEXTORAW
syn keyword plsqlFunction NLS_CHARSET_DECL_LEN NLS_CHARSET_ID NLS_CHARSET_NAME
syn keyword plsqlFunction NLS_INITCAP NLS_LOWER NLSSORT NLS_UPPER NULLFN NULLIF
syn keyword plsqlFunction NUMTODSINTERVAL NUMTOYMINTERVAL NVL POWER
syn keyword plsqlFunction RAISE_APPLICATION_ERROR RAWTOHEX RAWTONHEX REF
syn keyword plsqlFunction REFTOHEX REPLACE ROLLBACK_NR ROLLBACK_SV ROLLUP ROUND
syn keyword plsqlFunction ROWIDTOCHAR ROWIDTONCHAR ROWLABEL RPAD RTRIM
syn keyword plsqlFunction SAVEPOINT SESSIONTIMEZONE SETBND SET_TRANSACTION_USE
syn keyword plsqlFunction SIGN SIN SINH SOUNDEX SQLCODE SQLERRM SQRT STDDEV
syn keyword plsqlFunction SUBSTR SUBSTR2 SUBSTR4 SUBSTRB SUBSTRC SUM
syn keyword plsqlFunction SYS_AT_TIME_ZONE SYS_CONTEXT SYSDATE SYS_EXTRACT_UTC
syn keyword plsqlFunction SYS_GUID SYS_LITERALTODATE SYS_LITERALTODSINTERVAL
syn keyword plsqlFunction SYS_LITERALTOTIME SYS_LITERALTOTIMESTAMP
syn keyword plsqlFunction SYS_LITERALTOTZTIME SYS_LITERALTOTZTIMESTAMP
syn keyword plsqlFunction SYS_LITERALTOYMINTERVAL SYS_OVER__DD SYS_OVER__DI
syn keyword plsqlFunction SYS_OVER__ID SYS_OVER_IID SYS_OVER_IIT
syn keyword plsqlFunction SYS_OVER__IT SYS_OVER__TI SYS_OVER__TT
syn keyword plsqlFunction SYSTIMESTAMP TAN TANH TO_ANYLOB TO_BLOB TO_CHAR
syn keyword plsqlFunction TO_CLOB TO_DATE TO_DSINTERVAL TO_LABEL TO_MULTI_BYTE
syn keyword plsqlFunction TO_NCHAR TO_NCLOB TO_NUMBER TO_RAW TO_SINGLE_BYTE
syn keyword plsqlFunction TO_TIME TO_TIMESTAMP TO_TIMESTAMP_TZ TO_TIME_TZ
syn keyword plsqlFunction TO_YMINTERVAL TRANSLATE TREAT TRIM TRUNC TZ_OFFSET UID
syn keyword plsqlFunction UNISTR UPPER UROWID USER USERENV VALUE VARIANCE
syn keyword plsqlFunction VSIZE WORK XOR
syn match   plsqlFunction "\<SYS\$LOB_REPLICATION\>"


    " Predefined exceptions.

syn keyword plsqlException ACCESS_INTO_NULL CASE_NOT_FOUND COLLECTION_IS_NULL
syn keyword plsqlException CURSOR_ALREADY_OPEN DUP_VAL_ON_INDEX INVALID_CURSOR
syn keyword plsqlException INVALID_NUMBER LOGIN_DENIED NO_DATA_FOUND
syn keyword plsqlException NOT_LOGGED_ON PROGRAM_ERROR ROWTYPE_MISMATCH
syn keyword plsqlException SELF_IS_NULL STORAGE_ERROR SUBSCRIPT_BEYOND_COUNT
syn keyword plsqlException SUBSCRIPT_OUTSIDE_LIMIT SYS_INVALID_ROWID
syn keyword plsqlException TIMEOUT_ON_RESOURCE TOO_MANY_ROWS VALUE_ERROR
syn keyword plsqlException ZERO_DIVIDE 


    " Oracle Pseudo Columns.

syn keyword plsqlPseudo  CURRVAL LEVEL NEXTVAL ROWID ROWNUM


if exists("plsql_highlight_triggers")
    syn keyword plsqlTrigger  INSERTING UPDATING DELETING
endif


    " Conditionals.

syn keyword plsqlConditional ELSIF ELSE IF
syn match   plsqlConditional "\<END\s\+IF\>"


    " Loops.

syn keyword plsqlRepeat FOR LOOP WHILE FORALL
syn match   plsqlRepeat "\<END\s\+LOOP\>"


    " Various types of comments.
    " 20010723az: Added the ability to treat strings within comments just like
    " C does.

if exists("c_comment_strings")
    syntax match plsqlCommentSkip contained "^\s*\*\($\|\s\+\)"
    syntax region plsqlCommentString contained start=+L\="+ skip=+\\\\\|\\"+ end=+"+ end=+\*/+me=s-1 contains=plsqlCommentSkip
    syntax region plsqlComment2String contained start=+L\="+ skip=+\\\\\|\\"+ end=+"+ end="$"
    syntax region plsqlCommentL start="--" skip="\\$" end="$" keepend contains=@plsqlCommentGroup,plsqlComment2String,plsqlCharLiteral,plsqlBooleanLiteral,plsqlNumbersCom,plsqlSpaceError
    syntax region plsqlComment start="/\*" end="\*/" contains=@plsqlCommentGroup,plsqlComment2String,plsqlCharLiteral,plsqlBooleanLiteral,plsqlNumbersCom,plsqlSpaceError
else
    syntax region plsqlCommentL start="--" skip="\\$" end="$" keepend contains=@plsqlCommentGroup,plsqlSpaceError
    syntax region plsqlComment start="/\*" end="\*/" contains=@plsqlCommentGroup,plsqlSpaceError
endif

    " 20010723az: These are the old comment commands ... commented out.
" syn match   plsqlComment    "--.*$" contains=plsqlTodo
" syn region  plsqlComment    start="/\*" end="\*/" contains=plsqlTodo

syn sync ccomment plsqlComment
syn sync ccomment plsqlCommentL


    " To catch unterminated string literals.

syn match   plsqlStringError    "'.*$"


    " Various types of literals.
    " 20010723az: Added stuff for comment matching.

syn match plsqlNumbers transparent "\<[+-]\=\d\|[+-]\=\.\d" contains=plsqlIntLiteral,plsqlFloatLiteral
syn match plsqlNumbersCom contained transparent "\<[+-]\=\d\|[+-]\=\.\d" contains=plsqlIntLiteral,plsqlFloatLiteral
syn match plsqlIntLiteral contained "[+-]\=\d\+"
syn match plsqlFloatLiteral contained "[+-]\=\d\+\.\d*"
syn match plsqlFloatLiteral contained "[+-]\=\d*\.\d*"
"syn match plsqlFloatLiteral "[+-]\=\([0-9]*\.[0-9]\+\|[0-9]\+\.[0-9]\+\)\(e[+-]\=[0-9]\+\)\="
syn match   plsqlCharLiteral    "'[^']'"
syn match   plsqlStringLiteral  "'\([^']\|''\)*'"
syn keyword plsqlBooleanLiteral TRUE FALSE NULL


    " The built-in types.

syn keyword plsqlStorage ANYDATA ANYTYPE BFILE BINARY_INTEGER BLOB BOOLEAN
syn keyword plsqlStorage BYTE CHAR CHARACTER CLOB CURSOR DATE DAY DEC DECIMAL
syn keyword plsqlStorage DOUBLE DSINTERVAL_UNCONSTRAINED FLOAT HOUR
syn keyword plsqlStorage INT INTEGER INTERVAL LOB LONG MINUTE
syn keyword plsqlStorage MLSLABEL MONTH NATURAL NATURALN NCHAR NCHAR_CS NCLOB
syn keyword plsqlStorage NUMBER NUMERIC NVARCHAR PLS_INT PLS_INTEGER
syn keyword plsqlStorage POSITIVE POSITIVEN PRECISION RAW REAL RECORD
syn keyword plsqlStorage SECOND SIGNTYPE SMALLINT STRING SYS_REFCURSOR TABLE TIME
syn keyword plsqlStorage TIMESTAMP TIMESTAMP_UNCONSTRAINED
syn keyword plsqlStorage TIMESTAMP_TZ_UNCONSTRAINED
syn keyword plsqlStorage TIMESTAMP_LTZ_UNCONSTRAINED UROWID VARCHAR
syn keyword plsqlStorage VARCHAR2 YEAR YMINTERVAL_UNCONSTRAINED ZONE


    " A type-attribute is really a type.
    " 20020916bp: Removed leading part of pattern to avoid highlighting the
    "             object

syn match   plsqlTypeAttribute  "%\(TYPE\|ROWTYPE\)\>"


    " All other attributes.

syn match   plsqlAttribute "%\(BULK_EXCEPTIONS\|BULK_ROWCOUNT\|ISOPEN\|FOUND\|NOTFOUND\|ROWCOUNT\)\>"


    " Catch errors caused by wrong parentheses and brackets
    " 20010723az: significantly more powerful than the values -- commented out
    " below the replaced values. This adds the C functionality to PL/SQL.

syn cluster plsqlParenGroup contains=plsqlParenError,@plsqlCommentGroup,plsqlCommentSkip,plsqlIntLiteral,plsqlFloatLiteral,plsqlNumbersCom
if exists("c_no_bracket_error")
    syn region plsqlParen transparent start='(' end=')' contains=ALLBUT,@plsqlParenGroup
    syn match plsqlParenError ")"
    syn match plsqlErrInParen contained "[{}]"
else
    syn region plsqlParen transparent start='(' end=')' contains=ALLBUT,@plsqlParenGroup,plsqlErrInBracket
    syn match plsqlParenError "[\])]"
    syn match plsqlErrInParen contained "[{}]"
    syn region plsqlBracket transparent start='\[' end=']' contains=ALLBUT,@plsqlParenGroup,plsqlErrInParen
    syn match plsqlErrInBracket contained "[);{}]"
endif
" syn region plsqlParen       transparent start='(' end=')' contains=ALLBUT,plsqlParenError
" syn match plsqlParenError   ")"


    " Syntax Synchronizing
syn sync minlines=10 maxlines=100


    " Define the default highlighting.
    " For version 5.x and earlier, only when not done already.
    " For version 5.8 and later, only when and item doesn't have highlighting
    " yet.

if version >= 508 || !exists("did_plsql_syn_inits")
    if version < 508
        let did_plsql_syn_inits = 1
        command -nargs=+ HiLink hi link <args>
    else
        command -nargs=+ HiLink hi def link <args>
    endif

    HiLink plsqlAttribute       Macro
    HiLink plsqlBlockError	Error
    HiLink plsqlBooleanLiteral  Boolean
    HiLink plsqlCharLiteral     Character
    HiLink plsqlComment         Comment
    HiLink plsqlCommentL        Comment
    HiLink plsqlConditional     Conditional
    HiLink plsqlError           Error
    HiLink plsqlErrInBracket    Error
    HiLink plsqlErrInBlock	Error
    HiLink plsqlErrInParen      Error
    HiLink plsqlException       Function
    HiLink plsqlFloatLiteral    Float
    HiLink plsqlFunction        Function
    HiLink plsqlGarbage         Error
    HiLink plsqlHostIdentifier  Label
    HiLink plsqlIdentifier      Normal
    HiLink plsqlIntLiteral      Number
    HiLink plsqlOperator        Operator
    HiLink plsqlParen           Normal
    HiLink plsqlParenError      Error
    HiLink plsqlSpaceError      Error
    HiLink plsqlPseudo          PreProc
    HiLink plsqlKeyword         Keyword
    HiLink plsqlRepeat          Repeat
    HiLink plsqlStorage         StorageClass
    HiLink plsqlSQLKeyword      Function
    HiLink plsqlStringError     Error
    HiLink plsqlStringLiteral   String
    HiLink plsqlCommentString   String
    HiLink plsqlComment2String  String
    HiLink plsqlSymbol          Normal
    HiLink plsqlTrigger         Function
    HiLink plsqlTypeAttribute   StorageClass
    HiLink plsqlTodo            Todo

    delcommand HiLink
endif

let b:current_syntax = "plsql"

" vim: ts=8 sw=4
