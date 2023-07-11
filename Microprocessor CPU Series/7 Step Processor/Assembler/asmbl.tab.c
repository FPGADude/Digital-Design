/* A Bison parser, made by GNU Bison 2.4.2.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C
   
      Copyright (C) 1984, 1989-1990, 2000-2006, 2009-2010 Free Software
   Foundation, Inc.
   
   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.
   
   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.4.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1

/* Using locations.  */
#define YYLSP_NEEDED 0



/* Copy the first part of user declarations.  */

/* Line 189 of yacc.c  */
#line 5 "asmbl.y"


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "asmbl.h"

/*************************************************************************************************/
/* Global data space - Bad programming style, but, eh - whatcha gonna do?                        */
/*************************************************************************************************/

unsigned int debug_mode = 0; //display ugly debugging info
unsigned int listing = 0;    //output listing of assembly
out_type     out_format = BINARY; //How to format the output

unsigned char current_address;
int           current_opcode;
int           operand1, operand2;
unsigned int  num_operands;
unsigned int  line_number;

unsigned char memory[ 256 ];

label labels[ MAX_LABELS ];
int   num_labels;

char infile_name[ 100 ], outfile_name[ 100 ], listfile_name[ 100 ];
FILE *infile, *outfile, *listfile;



/* Line 189 of yacc.c  */
#line 104 "asmbl.tab.c"

/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif


/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     REG_REG_MNEMONIC = 258,
     LABEL = 259,
     MNEMONIC0 = 260,
     MNEMONIC1 = 261,
     MNEMONIC2 = 262,
     OPERAND = 263,
     COMMENT = 264,
     VALUE = 265,
     REGNAME = 266,
     COMMA = 267,
     EOL = 268,
     BYTE_DIRECTIVE = 269,
     SHORT_DIRECTIVE = 270,
     INT_DIRECTIVE = 271,
     ORG_DIRECTIVE = 272,
     EQU_DIRECTIVE = 273
   };
#endif



#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif


/* Copy the second part of user declarations.  */


/* Line 264 of yacc.c  */
#line 164 "asmbl.tab.c"

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int yyi)
#else
static int
YYID (yyi)
    int yyi;
#endif
{
  return yyi;
}
#endif

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)				\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack_alloc, Stack, yysize);			\
	Stack = &yyptr->Stack_alloc;					\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  16
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   53

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  19
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  15
/* YYNRULES -- Number of rules.  */
#define YYNRULES  34
/* YYNRULES -- Number of states.  */
#define YYNSTATES  62

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   273

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint8 yyprhs[] =
{
       0,     0,     3,     4,     6,     8,    11,    13,    17,    20,
      23,    26,    29,    34,    40,    48,    49,    51,    52,    54,
      56,    58,    60,    62,    66,    68,    70,    72,    74,    79,
      86,    91,    93,    95,    97
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int8 yyrhs[] =
{
      20,     0,    -1,    -1,    21,    -1,    22,    -1,    22,    21,
      -1,    13,    -1,     4,    24,    13,    -1,     9,    13,    -1,
      28,    13,    -1,    31,    13,    -1,    33,    13,    -1,    23,
       5,    24,    13,    -1,    23,     6,    25,    24,    13,    -1,
      23,     7,    11,    12,    25,    24,    13,    -1,    -1,     4,
      -1,    -1,     9,    -1,    11,    -1,    10,    -1,     4,    -1,
      27,    -1,    27,    12,    26,    -1,    10,    -1,     4,    -1,
      29,    -1,    30,    -1,    23,    17,    10,    24,    -1,    23,
      18,     4,    12,    10,    24,    -1,    23,    32,    26,    24,
      -1,    14,    -1,    15,    -1,    16,    -1,    23,     3,    11,
      12,    11,    24,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint8 yyrline[] =
{
       0,    43,    43,    44,    47,    48,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    62,    63,    66,    67,    70,
      71,    72,    75,    76,    79,    80,    83,    84,    87,    88,
      89,    91,    92,    93,    96
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "REG_REG_MNEMONIC", "LABEL", "MNEMONIC0",
  "MNEMONIC1", "MNEMONIC2", "OPERAND", "COMMENT", "VALUE", "REGNAME",
  "COMMA", "EOL", "BYTE_DIRECTIVE", "SHORT_DIRECTIVE", "INT_DIRECTIVE",
  "ORG_DIRECTIVE", "EQU_DIRECTIVE", "$accept", "program", "statement_list",
  "statement", "optional_label", "optional_comment", "operand", "arglist",
  "arg", "directive_statement", "org_statement", "equ_statement",
  "dataset_statement", "dataset_directive", "regreg_statement", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    19,    20,    20,    21,    21,    22,    22,    22,    22,
      22,    22,    22,    22,    22,    23,    23,    24,    24,    25,
      25,    25,    26,    26,    27,    27,    28,    28,    29,    30,
      31,    32,    32,    32,    33
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     1,     1,     2,     1,     3,     2,     2,
       2,     2,     4,     5,     7,     0,     1,     0,     1,     1,
       1,     1,     1,     3,     1,     1,     1,     1,     4,     6,
       4,     1,     1,     1,     6
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
      15,    16,     0,     6,     0,     3,    15,     0,     0,    26,
      27,     0,     0,    18,     0,     8,     1,     5,     0,    17,
       0,     0,    31,    32,    33,     0,     0,     0,     9,    10,
      11,     7,     0,     0,    21,    20,    19,    17,     0,    17,
       0,    25,    24,    17,    22,     0,    12,     0,     0,    28,
       0,    30,     0,    17,    13,    17,    17,    23,    34,     0,
      29,    14
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
      -1,     4,     5,     6,     7,    14,    37,    43,    44,     8,
       9,    10,    11,    27,    12
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -20
static const yytype_int8 yypact[] =
{
      17,    -7,    -6,   -20,     8,   -20,    19,    -2,    -4,   -20,
     -20,    -3,     9,   -20,    14,   -20,   -20,   -20,     0,    20,
      29,    24,   -20,   -20,   -20,    28,    37,    21,   -20,   -20,
     -20,   -20,    30,    31,   -20,   -20,   -20,    20,    33,    20,
      34,   -20,   -20,    20,    35,    32,   -20,    36,    29,   -20,
      38,   -20,    21,    20,   -20,    20,    20,   -20,   -20,    39,
     -20,   -20
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -20,   -20,    44,   -20,   -20,   -19,     3,     1,   -20,   -20,
     -20,   -20,   -20,   -20,   -20
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -18
static const yytype_int8 yytable[] =
{
      33,    18,    13,    19,    20,    21,   -17,    15,    16,    28,
      29,    32,    22,    23,    24,    25,    26,    -2,    47,    -4,
      49,     1,    30,     1,    51,    41,     2,    31,     2,    13,
       3,    42,     3,    34,    58,    38,    59,    60,    39,    35,
      36,    40,    45,    53,    46,    48,    50,    52,    56,    54,
      17,    55,    61,    57
};

static const yytype_uint8 yycheck[] =
{
      19,     3,     9,     5,     6,     7,    13,    13,     0,    13,
      13,    11,    14,    15,    16,    17,    18,     0,    37,     0,
      39,     4,    13,     4,    43,     4,     9,    13,     9,     9,
      13,    10,    13,     4,    53,    11,    55,    56,    10,    10,
      11,     4,    12,    11,    13,    12,    12,    12,    10,    13,
       6,    48,    13,    52
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,     4,     9,    13,    20,    21,    22,    23,    28,    29,
      30,    31,    33,     9,    24,    13,     0,    21,     3,     5,
       6,     7,    14,    15,    16,    17,    18,    32,    13,    13,
      13,    13,    11,    24,     4,    10,    11,    25,    11,    10,
       4,     4,    10,    26,    27,    12,    13,    24,    12,    24,
      12,    24,    12,    11,    13,    25,    10,    26,    24,    24,
      24,    13
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  However,
   YYFAIL appears to be in use.  Nevertheless, it is formally deprecated
   in Bison 2.4.2's NEWS entry, where a plan to phase it out is
   discussed.  */

#define YYFAIL		goto yyerrlab
#if defined YYFAIL
  /* This is here to suppress warnings from the GCC cpp's
     -Wunused-macros.  Normally we don't worry about that warning, but
     some users do, and we want to make it easy for users to remove
     YYFAIL uses, which will produce warnings from Bison 2.5.  */
#endif

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (YYLEX_PARAM)
#else
# define YYLEX yylex ()
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *yybottom, yytype_int16 *yytop)
#else
static void
yy_stack_print (yybottom, yytop)
    yytype_int16 *yybottom;
    yytype_int16 *yytop;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule)
#else
static void
yy_reduce_print (yyvsp, yyrule)
    YYSTYPE *yyvsp;
    int yyrule;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       );
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule); \
} while (YYID (0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yymsg, yytype, yyvaluep)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  YYUSE (yyvaluep);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

      default:
	break;
    }
}

/* Prevent warnings from -Wmissing-prototypes.  */
#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */


/* The lookahead symbol.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;



/*-------------------------.
| yyparse or yypush_parse.  |
`-------------------------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{


    int yystate;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus;

    /* The stacks and their tools:
       `yyss': related to states.
       `yyvs': related to semantic values.

       Refer to the stacks thru separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* The state stack.  */
    yytype_int16 yyssa[YYINITDEPTH];
    yytype_int16 *yyss;
    yytype_int16 *yyssp;

    /* The semantic value stack.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs;
    YYSTYPE *yyvsp;

    YYSIZE_T yystacksize;

  int yyn;
  int yyresult;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  yytoken = 0;
  yyss = yyssa;
  yyvs = yyvsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */
  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack.  Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	yytype_int16 *yyss1 = yyss;

	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),
		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	yytype_int16 *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
	YYSTACK_RELOCATE (yyss_alloc, yyss);
	YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token.  */
  yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 3:

/* Line 1464 of yacc.c  */
#line 44 "asmbl.y"
    { ;}
    break;

  case 4:

/* Line 1464 of yacc.c  */
#line 47 "asmbl.y"
    { IFDEBUG printf( "Single statement\n" ); ;}
    break;

  case 5:

/* Line 1464 of yacc.c  */
#line 48 "asmbl.y"
    { IFDEBUG printf( "Recursive statement\n" ); ;}
    break;

  case 6:

/* Line 1464 of yacc.c  */
#line 51 "asmbl.y"
    { ;}
    break;

  case 7:

/* Line 1464 of yacc.c  */
#line 52 "asmbl.y"
    { IFDEBUG printf( "LABEL\n" ); ;}
    break;

  case 8:

/* Line 1464 of yacc.c  */
#line 53 "asmbl.y"
    { IFDEBUG printf( "COMMENT\n" ); ;}
    break;

  case 9:

/* Line 1464 of yacc.c  */
#line 54 "asmbl.y"
    { IFDEBUG printf( "DIRECTIVE_STATEMENT\n" ); ;}
    break;

  case 10:

/* Line 1464 of yacc.c  */
#line 55 "asmbl.y"
    { IFDEBUG printf( "DATASET list STATEMENT\n" ); ;}
    break;

  case 11:

/* Line 1464 of yacc.c  */
#line 56 "asmbl.y"
    { IFDEBUG printf( "OPC R,R\n" ); ;}
    break;

  case 12:

/* Line 1464 of yacc.c  */
#line 57 "asmbl.y"
    { IFDEBUG printf( "CMD\n" ); ;}
    break;

  case 13:

/* Line 1464 of yacc.c  */
#line 58 "asmbl.y"
    { IFDEBUG printf( "CMD (1)\n" ); ;}
    break;

  case 14:

/* Line 1464 of yacc.c  */
#line 59 "asmbl.y"
    { IFDEBUG printf( "CMD (2)\n" ); ;}
    break;

  case 15:

/* Line 1464 of yacc.c  */
#line 62 "asmbl.y"
    {;}
    break;

  case 16:

/* Line 1464 of yacc.c  */
#line 63 "asmbl.y"
    { IFDEBUG printf( "Label\n" );;}
    break;

  case 17:

/* Line 1464 of yacc.c  */
#line 66 "asmbl.y"
    {;}
    break;

  case 18:

/* Line 1464 of yacc.c  */
#line 67 "asmbl.y"
    { IFDEBUG printf( "(comment)\n" ); ;}
    break;

  case 19:

/* Line 1464 of yacc.c  */
#line 70 "asmbl.y"
    { IFDEBUG printf( "Operand is REG\n" );;}
    break;

  case 20:

/* Line 1464 of yacc.c  */
#line 71 "asmbl.y"
    { IFDEBUG printf( "Operand is label\n" ); ;}
    break;

  case 21:

/* Line 1464 of yacc.c  */
#line 72 "asmbl.y"
    { IFDEBUG printf( "Operand is label" ); ;}
    break;

  case 22:

/* Line 1464 of yacc.c  */
#line 75 "asmbl.y"
    { IFDEBUG printf( "ARG\n" ); ;}
    break;

  case 23:

/* Line 1464 of yacc.c  */
#line 76 "asmbl.y"
    { IFDEBUG printf( "ARG list\n" ); ;}
    break;

  case 24:

/* Line 1464 of yacc.c  */
#line 79 "asmbl.y"
    { IFDEBUG printf( "VALUE_ARG\n" ); ;}
    break;

  case 25:

/* Line 1464 of yacc.c  */
#line 80 "asmbl.y"
    { IFDEBUG printf( "LABEL_ARG\n" ); ;}
    break;

  case 26:

/* Line 1464 of yacc.c  */
#line 83 "asmbl.y"
    { IFDEBUG printf( ".ORG\n" ); ;}
    break;

  case 27:

/* Line 1464 of yacc.c  */
#line 84 "asmbl.y"
    { IFDEBUG printf( ".EQU\n" ); ;}
    break;

  case 28:

/* Line 1464 of yacc.c  */
#line 87 "asmbl.y"
    { IFDEBUG printf( "ORG DIRECTIVE\n" ); ;}
    break;

  case 29:

/* Line 1464 of yacc.c  */
#line 88 "asmbl.y"
    { IFDEBUG printf( "EQU DIRECTIVE\n" ); ;}
    break;

  case 30:

/* Line 1464 of yacc.c  */
#line 89 "asmbl.y"
    { IFDEBUG printf( "DATA DIRECTIVE with list\n" ); ;}
    break;

  case 31:

/* Line 1464 of yacc.c  */
#line 91 "asmbl.y"
    { IFDEBUG printf( ".BYTE\n" ); ;}
    break;

  case 32:

/* Line 1464 of yacc.c  */
#line 92 "asmbl.y"
    { IFDEBUG printf( ".SHORT\n" ); ;}
    break;

  case 33:

/* Line 1464 of yacc.c  */
#line 93 "asmbl.y"
    { IFDEBUG printf( ".INT\n" ); ;}
    break;

  case 34:

/* Line 1464 of yacc.c  */
#line 96 "asmbl.y"
    { IFDEBUG printf( "OPC R,R statement\n"); ;}
    break;



/* Line 1464 of yacc.c  */
#line 1634 "asmbl.tab.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;

  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (yymsg);
	  }
	else
	  {
	    yyerror (YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
	{
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
	}
      else
	{
	  yydestruct ("Error: discarding",
		      yytoken, &yylval);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;


      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  *++yyvsp = yylval;


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#if !defined(yyoverflow) || YYERROR_VERBOSE
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}



/* Line 1684 of yacc.c  */
#line 98 "asmbl.y"


/*===============================================================================================*/
/* find_label - find a label in the label list                                                   */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string to look for                                      */
/* Output: if the label is found, return the index into the table.  If not, return -1            */
/*===============================================================================================*/
int find_label( char *name )
{
  int status = -1;
  int loop;
  
  for( loop = 0; loop < MAX_LABELS; loop++ )
  {
    if( strcmp( name, labels[ loop ].name ) == 0 ) break;
  }
  
  if( loop < MAX_LABELS )
    status = loop;
  
  
  return status;
}

/*===============================================================================================*/
/* new_known_label - add a label with a known location or value                                  */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         location is an int that is the address or value associated with the label             */
/* Output: if the label is found or created, return the index of the label.  If fail, return -1  */
/*===============================================================================================*/
int new_known_label( char *name, int location )
{
  int status;
  int loop;
  
  status = find_label( name );
  if( status >= 0 ) //if found in list already
  {
    if( labels[ status ].assigned ) 
      fprintf( stderr, "WARNING: Label %s already defined, being redefined in line %d?\n", name, line_number );
    labels[ status ].location = location;
    labels[ status ].assigned = 1;
    //labels[ status ].references = 0;
  }
  else //if not found in the existing list
  {
    if( num_labels < MAX_LABELS ) //only if room for new labels
    {
      strcpy( labels[ num_labels ].name, name );
      labels[ num_labels ].location = location;
      labels[ num_labels ].assigned = 1;
      for( loop = 0; loop < 100; loop++ )
        labels[ num_labels ].linkage[ loop ] = -1;
      labels[ num_labels ].references = 0;
      status = num_labels;
      num_labels++;
    }
  }
  
  return status;
}

/*===============================================================================================*/
/* new_forward_label - add a label with an yet unknown location or value                         */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         link_me is an int containint the address of the opcode where the label is referenced  */
/* Output: if the label is found or created, return the index of the label.  If fail, return -1  */
/*===============================================================================================*/
int new_forward_label( char *name, int link_me )
{
  int status;
  int loop;
  
  status = find_label( name );
  if( status > -1 ) //if found in the list already
  {
    labels[ status ].linkage[ labels[ status ].references++ ] = link_me;
  }
  else //new label to be added
  {
    strcpy( labels[ num_labels ].name, name );
    labels[ num_labels ].location = 0xFFFFFFFF; //unknown location
    labels[ num_labels ].assigned = 0;
    labels[ num_labels ].linkage[ 0 ] = link_me;
    for( loop = 1; loop < 100; loop++ )
      labels[ num_labels ].linkage[ loop ] = -1;
    labels[ num_labels ].references = 1;
    status = num_labels;
    num_labels++;
  }
  
  return status;
}

/*===============================================================================================*/
/* add_reference_to_label - add a reference to a label                                           */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         link_me is an int containint the address of the opcode where the label is referenced  */
/* Output: if the label is found or created, return the index of the label.  If fail, return -1  */
/*===============================================================================================*/
int add_reference_to_label( char *name, int link_me )
{
  int status = find_label( name );
  
  if( status > -1 ) //if found in list
  {
    if( labels[ status ].references < 100 )
    {
      labels[ status ].references++;
    }
    else //too many references
    {
      fprintf( stderr, "Too many renferences to %s\n", labels[ status ].name );
      status = -2;
    }
  }
  else //not found
  {
    status = new_forward_label( name, link_me );
  }
  
  return status;
}

/*===============================================================================================*/
/* equate_label - assign a value to a known label                                                */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  name is a char pointer to the string of the label name                                */
/*         value is an int that is the value to assign to the label                              */
/* Output: if the label is unknown, return -1.  Otherwise, return the index of the label         */
/*===============================================================================================*/
int equate_label( char *name, int value )
{
  int status = find_label( name );
  
  if( status > -1 )
  {
    labels[ status ].location = value;
    labels[ status ].assigned = 1;
  }
  
  return status;
}

/*===============================================================================================*/
/* mnemonic - convert mnemonic (string) to opcode (binary)                                       */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  word is a char pointer to the string of the mnemonic                                  */
/* Output: return the opcode (8-bit binary) or -1 if invalid word                                */
/*===============================================================================================*/
int mnemonic( char *word )
{
  int status=-1;
  
  if( strcmp( word, "LD" ) == 0 )
  {
    status = 0;
  }
  else if( strcmp( word, "ST" ) == 0 )
  {
    status = 0x10;
  }
  else if( strcmp( word, "DATA" ) == 0 )
  {
    status = 0x20;
  }
  else if( strcmp( word, "JMPR" ) == 0 )
  {
    status = 0x30;
  }
  else if( strcmp( word, "JMP" ) == 0 )
  {
    status = 0x40;
  }
  else if( strcmp( word, "JA" ) == 0 )
  {
    status = 0x54;
  }
  else if( strcmp( word, "JC" ) == 0 )
  {
    status = 0x58;
  }
  else if( strcmp( word, "JE" ) == 0 )
  {
    status = 0x52;
  }
  else if( strcmp( word, "JZ" ) == 0 )
  {
    status = 0x51;
  }
  else if( strcmp( word, "CLF" ) == 0 )
  {
    status = 0x60;
  }
  else if( strcmp( word, "IN" ) == 0 )
  {
    status = 0x70;
  }
  else if( strcmp( word, "OUT" ) == 0 )
  {
    status = 0x78;
  }
  else if( strcmp( word, "ADD" ) == 0 )
  {
    status = 0x80;
  }
  else if( strcmp( word, "SHR" ) == 0 )
  {
    status = 0x90;
  }
  else if( strcmp( word, "SHL" ) == 0 )
  {
    status = 0xA0;
  }
  else if( strcmp( word, "NOT" ) == 0 )
  {
    status = 0xB0;
  }
  else if( strcmp( word, "AND" ) == 0 )
  {
    status = 0xC0;
  }
  else if( strcmp( word, "OR" ) == 0 )
  {
    status = 0xD0;
  }
  else if( strcmp( word, "XOR" ) == 0 )
  {
    status = 0xE0;
  }
  else if( strcmp( word, "CMP" ) == 0 )
  {
    status = 0xF0;
  }
  else
  {
    fprintf( stderr, "Unknown assembly opcode: %s\n", word );
  }
  
  return status;
}

/*===============================================================================================*/
/* directive - convert string to directive code                                                  */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  word is a char pointer to the string of the directive                                 */
/* Output: return the directive code or -1 if invalid directive                                  */
/*===============================================================================================*/
int directive( char *word )
{
  int status = -1;
  
  if( strcmp( word, ".ORG" ) == 0 )
  {
    status = 0x100;
  }
  else if( strcmp( word, ".BYTE" ) == 0 )
  {
    status = 0x101;
  }
  else if( strcmp( word, ".SHORT" ) == 0 )
  {
    status = 0x102;
  }
  else if( strcmp( word, ".INT" ) == 0 )
  {
    status = 0x014;
  }
  else if( strcmp( word, ".ASCII" ) == 0 )
  {
    status = 0x110;
  }
  else if( strcmp( word, ".EQU" ) == 0 )
  {
    status = 0x120;
  }
  else
  {
    fprintf( stderr, "Unknown directive: %s\n", word );
  }
  
  return status;
}

/*===============================================================================================*/
/* register_name - convert a register name string to register number (2-bit binary)              */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  word is a char pointer to the string of the register name                             */
/* Output: return 0-3 if a valid register, or -1 if error                                        */
/*===============================================================================================*/
int register_name( char *word )
{
  int status = -1;
  
  if( ( word[ 1 ] < 0x34 ) && ( word[ 1 ] > 0x2F ) )
  {
    status = (int)( word[ 1 ] - 0x30 );
  }
  else
  {
    fprintf( stderr, "ERROR: Illegal register identifier: %s\n", word ); 
  }
  
  return status;
}

/*===============================================================================================*/
/*===============================================================================================*/
yyerror( char *s )
{
  fprintf( stderr, "yyerror: %s encountered at line %d\a\n", s, line_number );
}

/*===============================================================================================*/
/*===============================================================================================*/
int parse_parameters( int argc, char **argv )
{
  int loop;
  char *where;
  
  for( loop=1; loop<argc; loop++ ) //Do not process argv[0]
  {
    if( ( strcmp( argv[ loop ], "-d" ) == 0 )      ||
        ( strcmp( argv[ loop ], "-d+" ) == 0 )     ||
        ( strcmp( argv[ loop ], "/d" ) == 0 )      ||
        ( strcmp( argv[ loop ], "/d+" ) == 0 )    ||
        ( strcmp( argv[ loop ], "--debug" ) == 0 ) ||
        ( strcmp( argv[ loop ], "/debug" ) == 0  )    ) //enter debug mode
    {
      debug_mode = 1;
    }
    else if( ( strcmp( argv[ loop ], "-d-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/d-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--nodebug" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/nodebug" ) == 0  )    ) //exit debug mode
    {
      debug_mode = 0; //default
    }
    else if( ( strcmp( argv[ loop ], "-l" ) == 0 )      ||
        ( strcmp( argv[ loop ], "-l+" ) == 0 )     ||
        ( strcmp( argv[ loop ], "/l" ) == 0 )      ||
        ( strcmp( argv[ loop ], "/l+" ) == 0 )    ||
        ( strcmp( argv[ loop ], "--list" ) == 0 ) ||
        ( strcmp( argv[ loop ], "/list" ) == 0  )    ) //enable_listing
    {
      listing = 1;
    }
    else if( ( strcmp( argv[ loop ], "-l-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/l-" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--nolist" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/nolist" ) == 0  )    ) //disable listing
    {
      listing = 0; //default
    }
    else if( ( strcmp( argv[ loop ], "-i" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/i" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--intel" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/intel" ) == 0 )     ) //Intel output format
    {
      //out_format = INTEL;
      fprintf( stderr, "INTEL output format not yet implimented\n" );
    }
    else if( ( strcmp( argv[ loop ], "-m" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/m" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--motorola" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/motorola" ) == 0 )     ) //Motorola output format
    {
      //out_format = MOTOROLA;
      fprintf( stderr, "MOTOROLA output format not yet implimented\n" );
    }
    else if( ( strcmp( argv[ loop ], "-b" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/b" ) == 0 ) ||
             ( strcmp( argv[ loop ], "--binary" ) == 0 ) ||
             ( strcmp( argv[ loop ], "/binary" ) == 0 )     ) //Binary output format
    {
      out_format = BINARY; //default
    }
    else //Sure do hope this in an input file name!
    {
      strcpy( infile_name, argv[ loop ] );
      strcpy( outfile_name, argv[ loop ] );
      strcpy( listfile_name, argv[ loop ] );
      where = strstr( outfile_name, ".ASM" );
      if( !where ) where = strstr( outfile_name, ".asm" );
      if( !where )
      {
        fprintf( stderr, "Hmmm, I am assuming \"%s\" is an input file name.\n", infile_name );
        fprintf( stderr, "I was expecing it to in in \".ASM\" but since it doesn't, your output name will be weird.\n" );
        strcat( outfile_name, ".out" );
      }
      else
      {
        switch( out_format )
        {
          case BINARY:
            strcpy( where, ".bin" );
            break;
        
          case INTEL:
            strcpy( where, ".hex" );
            break;
        
          case MOTOROLA:
            strcpy( where, ".s19" );
            break;
        
          default:
            fprintf( stderr, "Unknown output format: %d, Cowardly aborting!\n", (int)out_format );
            return -1; //exit ugly!
        }
      }
      infile = fopen( infile_name, "r" );
      if( infile )
      {
        if( out_format == BINARY )
        {
          outfile = fopen( outfile_name, "wb" );
          if( outfile == NULL )
          {
            fclose( infile );
            fprintf( stderr, "Unable to output to binary file \"%s\" so I quit!\n", outfile_name );
            return -3;
          }  
        }
        else
        {
          outfile = fopen( outfile_name, "w" );
          if( outfile == NULL )
          {
            fclose( infile );
            fprintf( stderr, "Unable to output to file \"%s\" so I quit!\n", outfile_name );
            return -3;
          }
        }
        
        //At this point, both files are open
        if( listing )
        {
          where = strstr( listfile_name, ".ASM" );
          if( where == NULL ) where = strstr( listfile_name, ".asm" );
          if( where == NULL )
            strcat( listfile_name, ".lst" );
          else
            strcpy( where, ".lst" );
          
          listfile = fopen( listfile_name, "w" );
          if( listfile_name == NULL )
          {
            listing = 0;
            fprintf( stderr, "Unable to open listing file for output; continuing, but turning off listing.\n" );
          }
        }
        
        //Whew! Now, actually process the file!
        yyrestart( infile );
        num_labels = 0;
        current_address = 0;
        current_opcode = -1;
        line_number = 0;
        yyparse();
        show_labels();
        place_labels();
        show_memory();

        write_output();
        
        if( listing ) fclose( listfile );
        fclose( outfile );
        fclose( infile );
        outfile = stdout;
        
      }
      else
      {
        fprintf( stderr, "Unable to read \"%s\" so I quit!\n", infile_name );
        return -2;
      }
      
    }
  }
}


/*===============================================================================================*/
/* show_labels - print out the list of labels and their general information                      */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: Return int value that is the number of labels                                         */
/*===============================================================================================*/
int show_labels( void )
{
  int loop, loop1;
  
  printf( "Labels (%d):\n", num_labels );
  for( loop = 0; loop < num_labels; loop++ )
  {
    printf( "%c %2d: %-20s %04X %d", labels[ loop ].assigned == 0 ? '*' : ' ',
      loop, labels[ loop ].name, labels[ loop ].location, labels[ loop ].references ); 
    for( loop1 = 0; loop1 < labels[ loop ].references; loop1++ )
      printf( "[%X] ", labels[ loop ].linkage[ loop1 ] );
    printf( "\n" );
  }
  printf( "\n" );
  
  return num_labels;
}

/*===============================================================================================*/
/* place_labels - place the label values into memory                                             */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: Return int value that is the number of labels, or -1 if any labels are undefined      */
/*===============================================================================================*/
int place_labels( void )
{
  int label_loop, reference_loop;
  int status = num_labels;
  
  for( label_loop = 0; label_loop < num_labels; label_loop++ )
  {
    if( labels[ label_loop ].assigned )
    {
      for( reference_loop = 0; reference_loop < labels[ label_loop ].references; reference_loop++ )
        memory[ labels[ label_loop ].linkage[ reference_loop ] ] = labels[ label_loop ].location;
    }
    else
    {
      printf( "ERROR: Label %s is undefined.\n", labels[ label_loop ].name );
      status = -1;
    }
  }
  
  return status;
}

/*===============================================================================================*/
/* btoi - convert "########" from ASCII to binary integer                                        */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  string is a char pointer to the string to convert                                     */
/* Output: return the integer value                                                              */
/*===============================================================================================*/
int btoi( char *string )
{
  int value;
  
  value = 0;
  while( *string )
  {
    value = ( value << 1 ) | ( *string++ & 0x01 );
  }
  
  return value;
}

/*===============================================================================================*/
/* show_memory - display the 256-byte contents of memory in HEX                                  */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: return 0                                                                              */
/*===============================================================================================*/
int show_memory( void )
{
  int loop;
  
  printf( "Memory:\n" );
  for( loop = 0; loop < 256; loop++ )
  {
    if( ( loop > 0 ) && ( ( loop & 0x0F ) == 0 ) ) printf( "\n" );
    if( ( loop & 0x0F ) == 0 ) printf( "%02X: ", loop );
    printf( "%02X ", memory[ loop ] );
  }
  printf( "\n" );

  return 0;
}

/*===============================================================================================*/
/* write_output - write output to the binary file                                                */
/*-----------------------------------------------------------------------------------------------*/
/* Input:  -NONE-                                                                                */
/* Output: Return int value that is the length of memory written                                 */
/*===============================================================================================*/
int write_output( void )
{
  int count, file_no = fileno( outfile );
  
  if( out_format == BINARY )
  {
    count = write( file_no, memory, current_address );
  
    if( count != current_address ) count = -1;
  }
  else if( out_format == INTEL )
  {
    printf( "WARNING: INTEL output format not implmented yet.  Try BINARY instead.\n" );
    count = -2;
  }
  else if( out_format == MOTOROLA )
  {
    printf( "WARNING: MOTOROLA output format not implmented yet.  Try BINARY instead.\n" );
    count = -2;
  }
  else
    fprintf( stderr, "ERROR: Unknown output format.  No ountput generated\n" );
  
  return count;
}

/*===============================================================================================*/
/*===============================================================================================*/
int main( int argc, char **argv )
{
  parse_parameters( argc, argv );
  
  return 0;
}


