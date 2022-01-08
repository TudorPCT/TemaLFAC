%{
#include <stdio.h>
#include "tema.tab.h"
%}
%option noyywrap
%%
"int"|"float"|"char"|"string"|"bool" {yylval.strval=strdup(yytext);return TYPE;}
"struct" {return CUSTOMTYPE;}
"!" {return NOT;}
"main_" {return MAIN;}
"return" {return RTR;}
"while" {return WHILE;}
"for" {return FOR;}
"if" {return IF;}
"true" {yylval.intval=1; return NR;}
"==" {return EQ;}
"!=" {return NEQ;}
"><" {return NEQ;}
">=" {return GEQ;}
"<=" {return LEQ;}
">" {return G;}
"<"  {return S;}
"else" {return ELSE;}
"const" {yylval.strval=strdup(yytext); return CONST;}
"&&" {return AND;}
"||" {return OR;}
[a-zA-Z] {yylval.charval=yytext[0]; return CH;}
[_a-zA-Z][_a-zA-Z0-9]* {yylval.strval=strdup(yytext);return ID;}
":=" {return ASSIGN;}
[0-9]+ {yylval.intval=atoi(yytext); return NR;}
[0-9]+"."[0-9]+  {yylval.floatval=atof(yytext); return NRF;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}
