%{
#include <stdio.h>
#include "limbaj.tab.h"
%}
%option noyywrap
%%
"int"|"float"|"char"|"string" {return TIP;}
"main" {return MAIN;}
"begin" {return BGIN;}
"end" {return END;}
"return" {return RTR;}
[_a-zA-Z][_a-zA-Z0-9]* {return ID;}
":=" {return ASSIGN;}
[0-9]+ {return NR;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}
