%{
#include <stdio.h>
#include<string.h>
#include "tema.tab.h"
%}
%option noyywrap
%%
"_global_declaration_section_" {return DEC;}
"_func_section_" {return FS;}
"_main_section_" {return MAIN;}
"int"|"float"|"char"|"string"|"bool" {yylval.strval=strdup(yytext);return TYPE;}
"struct" {return CUSTOMTYPE;}
"!" {return NOT;}
"return" {return RTR;}
"while" {return WHILE;}
"for" {return FOR;}
"if" {return IF;}
"true" {yylval.intval=1; return NR;}
"false" {yylval.intval=0; return NR;}
"print" {return PRT;}
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
\'[_a-zA-Z/.^*\-+0-9 :]\' {yylval.charval=yytext[1];return CH;}
\"[_a-zA-Z/.^*\-+0-9 :]*\" {yytext = yytext+1; yytext[strlen(yytext)-1] = '\0'; yylval.strval=strdup(yytext);return STR;}
[0-9]+ {yylval.intval=atoi(yytext); return NR;}
[0-9]+"."[0-9]+  {yylval.floatval=atof(yytext); return NRF;}
[_a-zA-Z][_a-zA-Z0-9]* {yylval.strval=strdup(yytext);return ID;}
":=" {return ASSIGN;}
[ \t] ;
\n {yylineno++;}
. {return yytext[0];}
