%{
#include <stdio.h>
#include "tema.tab.h"
%}
%option noyywrap
%%
"int"|"float"|"char"|"string" {return TYPE;}
"struct" {return CUSTOMTYPE;}
"main" {return MAIN;}
"return" {return RTR;}

"while" {return WHILE;}
"for" {return FOR;}
"if" {return IF;}
"else" {return ELSE;}


[_a-zA-Z][_a-zA-Z0-9]* {return ID;}
":=" {return ASSIGN;}
[0-9]+ {return NR;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}
