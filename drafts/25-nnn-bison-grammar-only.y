/*
 * A Bison grammar for Phase 3 of the Fortran preprocessor.
 *
 * This grammar assumes source text has been processed
 * by phase 1 (line conjoining) and by phase 2 (comment
 * processing.
 *
 * This grammar assumes a lexical analyzer that handles
 * the places where the preprocessor input is sensitive
 * (or insensitive) to whitespace. This is to correctly
 * recognize indented directives, and when, for example,
 * an identifier is immediately followed by a parenthesis.
 * (An alternative syntax can be done by defining the
 * grammar with 'whitespace' and 1optional_whitespace'
 * non-terminals, but we leave it to your imagination
 * why that sounds better than it looks.)
 *
 * The lexical analyzer also recognizes tokens such as
 * identifiers, whole and real numbers, strings, Fortran and C
 * punctuation tokens.
 *
 * Preprocessor directives have a line-oriented syntax,
 * so many grammar rules end in an explicit EOL token.
 *
 * In general, the grammar rules follow the non-terminal
 * names used in Clause 6.10 of the C 23 programming language
 * standard (ISO/IEC 9899:2023, working draft N3096).
 *
 * The grammar rules for expressions represent the Fortran
 * standard's expression rules in clause 10.1.2.
 *
 * This grammar currently reflects FPP as described in
 * J3 paper 25-144.txt. Some rules are commented out as the
 * the current paper defines a very limited number of Fortran
 * operators that can be used in #if and #elif directives.
 */

%token HASH_DEFINE "#define"
%token HASH_ELIF "#elif"
%token HASH_ELIFDEF "#elifdef"
%token HASH_ELIFNDEF "#elifndef"
%token HASH_ELSE "#else"
%token HASH_ENDIF "#endif"
%token HASH_ERROR "#error"
%token HASH_IF "#if"
%token HASH_IFDEF "#ifdef"
%token HASH_IFNDEF "#ifndef"
%token HASH_INCLUDE "#include"
%token HASH_LINE "#line"
%token HASH_PRAGMA "#pragma"
%token HASH_UNDEF "#undef" /* catch-all for undefined directives */
%token HASH_WARNING "#warning"

%token AMPERSAND "&"
%token AMPERSAND_AMPERSAND "&&"
%token AT "@"
%token BANG "!"
%token BANG_EQ "!="
%token BAR "|"
%token BAR_BAR "||"
%token BRACKETED_STRING "< string >"
%token CARET "^"
%token COLON ":"
%token COLON_COLON "::"
%token COMMA ","
%token DOLLAR "$"
%token ELLIPSES "..."
%token EOL
%token EQ "="
%token EQ_EQ "=="
%token FORMAT "format"
%token GT ">"
%token GT_EQ ">="
%token GT_GT ">>"
%token HASH "#"
%token HASH_HASH "##"
%token HASH_INCLUDE_STRING
%token HASH_INCLUDE_BRACKETED_STRING
%token ID
%token ID_LPAREN                 /* only for #define functions */
%token IMPLICIT "implicit"
%token LBRACKET "["
%token LPAREN "("
%token LPAREN_SLASH "(/"
%token LT "<"
%token LT_EQ "<="
%token LT_LT "<<"
%token MINUS "-"
%token PERCENT "%"
%token PERIOD "."
%token PERIOD_AND_PERIOD ".and."
%token PERIOD_EQ_PERIOD ".eq."
%token PERIOD_EQV_PERIOD ".eqv."
%token PERIOD_FALSE_PERIOD ".false."
%token PERIOD_GE_PERIOD ".ge."
%token PERIOD_GT_PERIOD ".gt."
%token PERIOD_ID_PERIOD       /* user-defined operator */
%token PERIOD_LE_PERIOD ".le."
%token PERIOD_LT_PERIOD ".lt."
%token PERIOD_NE_PERIOD ".ne."
%token PERIOD_NEQV_PERIOD ".neqv."
%token PERIOD_NIL_PERIOD "nil."
%token PERIOD_NOT_PERIOD ".not."
%token PERIOD_OR_PERIOD ".or."
%token PERIOD_TRUE_PERIOD ".true."
%token PLUS "+"
%token EQ_GT "=>"
%token QUESTION "?"
%token RBRACKET "]"
%token REAL_NUMBER
%token RPAREN ")"
%token SEMICOLON ";"
%token SLASH "/"
%token SLASH_EQ "/="
%token SLASH_RPAREN "/)"
%token SLASH_SLASH "//"
%token STRING
%token TILDE "~"
%token TIMES "*"
%token TIMES_TIMES "**"
%token UNDERSCORE  "_"           /* for number_KIND, not ID */
%token WHOLE_NUMBER

%token UU_FILE_UU "__FILE__"
%token UU_LINE_UU "__LINE__"
%token UU_DATE_UU "__DATE__"
%token UU_TIME_UU "__TIME__"
%token UU_STDF_UU "__STDF__"
%token UU_VA_ARGS_UU "__VA_ARGS__"
%token UU_VA_OPT_UU "__VA_OPT__"

%nterm preprocessing_file
%nterm group_part
%nterm if_section
%nterm elif_groups
%nterm else_group
%nterm endif_line
%nterm control_line
%nterm identifier_list
%nterm non_directive
%nterm replacement_list
%nterm replacement_token
%nterm pp_tokens
%nterm pp_token
%nterm pp_token_except_parens_comma
%nterm pp_tokens_balanced_parens
%nterm fortran_tokens
%nterm fortran_token
%nterm fortran_token_except_parens_comma
%nterm fortran_token_except_format_implicit
%nterm fortran_token_anywhere
%nterm fortran_tokens_except_format_implicit
%nterm c_pp_token
%nterm expression
/* TBD %nterm equiv_op */
%nterm conditional_expr
%nterm logical_or_expr
%nterm or_op
%nterm logical_and_expr
%nterm and_op
%nterm inclusive_or_expr
%nterm exclusive_or_expr
%nterm and_expr
%nterm equality_expr
%nterm equality_op
%nterm relational_expr
%nterm relational_op
%nterm shift_expr
%nterm shift_op
%nterm character_expr
%nterm additive_expr
%nterm add_op
%nterm multiplicative_expr
%nterm mult_op
%nterm power_expr
%nterm unary_expr
%nterm unary_op
%nterm postfix_expr
%nterm actual_argument_list
%nterm primary_expr
%nterm predefined_identifier
%nterm fortran_source_line

%%


preprocessing_file:
                %empty
        |       group ;


group:
                group_part
        |       group group_part ;

group_opt:
                %empty
        |       group ;

/* A group_part is some directive, or some Fortran text. */
group_part:
                if_section
        |       control_line
        |       HASH non_directive
        |       fortran_source_line ;

if_section:
                if_group endif_line
        |       if_group elif_groups endif_line
        |       if_group elif_groups else_group endif_line ;

if_group:
                HASH_IF expression EOL group
        |       HASH_IFDEF ID EOL group
        |       HASH_IFNDEF ID EOL group ;

elif_groups:
                elif_group
        |       elif_groups elif_group ;

elif_group:
                HASH_ELIF expression EOL group_opt
        |       HASH_ELIFDEF ID EOL group_opt
        |       HASH_ELIFNDEF ID EOL group_opt ;

else_group:
                HASH_ELSE EOL group_opt ;

endif_line:
                HASH_ENDIF EOL ;

control_line:
                HASH_INCLUDE pp_tokens EOL
        |       HASH_DEFINE ID EOL
        |       HASH_DEFINE ID replacement_list EOL
        |       HASH_DEFINE ID_LPAREN identifier_list_opt RPAREN EOL
        |       HASH_DEFINE ID_LPAREN identifier_list_opt RPAREN replacement_list EOL
        |       HASH_LINE pp_tokens EOL
        |       HASH_ERROR EOL
        |       HASH_ERROR pp_tokens EOL
        |       HASH_WARNING EOL
        |       HASH_WARNING pp_tokens EOL
        |       HASH_PRAGMA pp_tokens EOL ;

identifier_list_opt:
                %empty
        |       identifier_list ;

identifier_list:
                ID
        |       identifier_list COMMA ID ;


non_directive:
                pp_tokens EOL ;

replacement_list:
                replacement_token
        |       replacement_list replacement_token ;

/*
 * '#' and '##' operators can only appear in the replacement
 * text in #define directives. (I may need to rethink that.)
 */
replacement_token:
                pp_token
        |       HASH
        |       HASH_HASH ;

pp_tokens:
                pp_token
        |       pp_tokens pp_token ;

pp_token:
                fortran_token
        |       c_pp_token ;

pp_token_except_parens_comma:
                fortran_token_except_parens_comma
        |       c_pp_token ;


/*
 * This should include every token that the tokenizer
 * could recognize. The tokenizer has to do some recognition
 * of Fortran operators (such as .AND.) and places where
 * preprocessing expansion should not * occur (such as FORMAT
 * and IMPLICIT).
 */

fortran_tokens:
                fortran_token
        |       fortran_tokens fortran_token ;

fortran_token:
                fortran_token_anywhere
        |       COMMA
        |       LPAREN
        |       RPAREN
        |       FORMAT
        |       IMPLICIT ;

fortran_token_except_parens_comma:
                fortran_token_anywhere
        |       FORMAT
        |       IMPLICIT ;

fortran_token_except_format_implicit:
                fortran_token_anywhere
        |       COMMA
        |       LPAREN
        |       RPAREN ;

fortran_token_anywhere:
                AT
        |       COLON
        |       COLON_COLON
        |       DOLLAR
        |       EQ
        |       EQ_EQ
        |       EQ_GT
        |       GT
        |       GT_EQ
        |       ID
        |       LBRACKET
        |       LT
        |       LT_EQ
        |       MINUS
        |       PERCENT
        |       PERIOD
        |       PERIOD_AND_PERIOD
     /* |       TBD PERIOD_EQ_PERIOD
        |       PERIOD_EQV_PERIOD */
        |       PERIOD_FALSE_PERIOD
     /* |       PERIOD_GE_PERIOD
        |       PERIOD_GT_PERIOD */
        |       PERIOD_ID_PERIOD        /* Any not needed by grammar */
     /* |       TBD PERIOD_NIL_PERIOD */
        |       PERIOD_NOT_PERIOD
        |       PERIOD_OR_PERIOD
        |       PERIOD_TRUE_PERIOD
        |       PLUS
        |       QUESTION
        |       RBRACKET
        |       REAL_NUMBER
        |       SEMICOLON
        |       SLASH
        |       SLASH_EQ
        |       SLASH_SLASH
        |       STRING
        |       TIMES
        |       TIMES_TIMES
        |       UNDERSCORE              /* for _KIND, not within ID */
        |       WHOLE_NUMBER ;

fortran_tokens_except_format_implicit:
                fortran_token_except_format_implicit
        |       fortran_tokens_except_format_implicit fortran_token_except_format_implicit ;

/*
 * Tokens that can appear in C preprocessor replacement text
 * in addition to the Fortran tokens.
 */
c_pp_token:
                AMPERSAND
        |       AMPERSAND_AMPERSAND
        |       BANG
        |       BANG_EQ
        |       BAR
        |       BAR_BAR
        |       CARET
        |       GT_GT
        |       LT_LT
        |       TILDE ;

/* Following Fortran ISO/IEC 1539-1:2023 Clause 10.1.2
 *
 * Modified to include C operators.
 */
expression:
                conditional_expr
     /* |       TBD expression equiv_op conditional_expr */ ;

/* TBD equiv_op:
                PERIOD_EQV_PERIOD
        |       PERIOD_NEQV_PERIOD ; */

conditional_expr:
                /* TBD logical_or_expr QUESTION expression COLON conditional_expr
        |*/     logical_or_expr ;

logical_or_expr:
                logical_and_expr
        |       logical_or_expr or_op logical_and_expr ;

or_op:
                BAR_BAR
        |       PERIOD_OR_PERIOD ;

logical_and_expr:
                inclusive_or_expr
        |       logical_and_expr and_op inclusive_or_expr ;

and_op:
                AMPERSAND_AMPERSAND
        |       PERIOD_AND_PERIOD ;

inclusive_or_expr:
                exclusive_or_expr
        |       inclusive_or_expr BAR exclusive_or_expr ;

exclusive_or_expr:
                and_expr
        |       exclusive_or_expr CARET and_expr ;

and_expr:
                equality_expr
        |       and_expr AMPERSAND equality_expr ;

equality_expr:
                relational_expr
        |       equality_expr equality_op relational_expr ;

equality_op:
                /* TBD PERIOD_EQ_PERIOD
        |       PERIOD_NE_PERIOD
        |*/     EQ_EQ
        |       EQ
        |       SLASH_EQ
        |       BANG_EQ ;

relational_expr:
                shift_expr
        |       relational_expr relational_op shift_expr ;

relational_op:
                /* TBD PERIOD_LE_PERIOD
        |       PERIOD_LT_PERIOD
        |       PERIOD_GE_PERIOD
        |       PERIOD_GT_PERIOD
        |*/     LT
        |       GT
        |       LT_EQ
        |       GT_EQ ;

shift_expr:
                character_expr
        |       shift_expr shift_op character_expr ;

shift_op:
                LT_LT
        |       GT_GT ;

character_expr:
                additive_expr
     /* |       TBD character_expr SLASH_SLASH additive_expr */ ;

additive_expr:
                multiplicative_expr
        |       additive_expr add_op multiplicative_expr ;

add_op:
                PLUS
        |       MINUS ;

multiplicative_expr:
                power_expr
        |       multiplicative_expr mult_op power_expr ;

mult_op:
                TIMES
        |       SLASH
        |       PERCENT ;

power_expr:
                unary_expr
      /* |       TBD unary_expr TIMES_TIMES power_expr */ ;

unary_expr:
                postfix_expr
        |       unary_op postfix_expr ;

unary_op:
                PLUS
        |       MINUS
        |       PERIOD_NOT_PERIOD
        |       BANG
        |       TILDE ;

postfix_expr:
                primary_expr
        |       ID LPAREN RPAREN
        |       ID LPAREN actual_argument_list RPAREN ;

actual_argument_list:
                pp_tokens_balanced_parens
        |       actual_argument_list COMMA pp_tokens_balanced_parens ;

pp_tokens_balanced_parens:
                pp_token_except_parens_comma
        |       LPAREN RPAREN
        |       LPAREN pp_tokens_balanced_parens RPAREN
        |       pp_tokens_balanced_parens pp_token_except_parens_comma
        |       pp_tokens_balanced_parens LPAREN RPAREN
        |       pp_tokens_balanced_parens LPAREN pp_tokens_balanced_parens RPAREN ;

primary_expr:
                WHOLE_NUMBER ;

primary_expr:
                ID
        |       PERIOD_FALSE_PERIOD
     /* |       TBD PERIOD_NIL_PERIOD */
        |       PERIOD_TRUE_PERIOD
        |       LPAREN expression RPAREN
        |       predefined_identifier ;

/* Identifiers known to the preprocessor (such as __FILE__) */
predefined_identifier:
                UU_FILE_UU
        |       UU_LINE_UU
        |       UU_DATE_UU
        |       UU_TIME_UU
        |       UU_STDF_UU
        |       UU_VA_ARGS_UU
        |       UU_VA_OPT_UU ;

fortran_source_line:
                EOL
        |       FORMAT fortran_tokens EOL
        |       IMPLICIT fortran_tokens EOL
        |       fortran_tokens_except_format_implicit EOL ;
