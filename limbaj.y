%{
#include <stdio.h>
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(char *s);
%}
%token ID TIP BEGIN END ASSIGN NR MAIN RTR
%start progr
%%

progr: declaratii functii mainbloc {printf("program corect sintactic\n");}
	 | declaratii mainbloc
	 | functii mainbloc
	 | mainbloc
     ;

declaratii :  declaratie ';'
	   | declaratii declaratie ';'
	   ;
declaratie : TIP ID 
           | TIP ID '(' lista_param ')'
           | TIP ID '(' ')'
           ;
lista_param : param
            | lista_param ','  param 
            ;
            
param : TIP ID
      ; 
	  
/* Functii */
functii : functie
		| functii functie
		;
functie : TIP ID '(' lista_param ')' bloc 
	;
	
/* Main */	
mainbloc : TIP MAIN '(' ')' bloc
	;
	
/* bloc */
bloc : BEGIN list END  
     ;
     
/* lista instructiuni */
list : declaratii list
     | list statement ';'
	 | retrn ';'
     ;
/* Return */
retrn : RTR ';'
	  |
/* instructiune */
statement: ID ASSIGN ID
         | ID ASSIGN NR 
         | ID '(' lista_apel ')'
         ;
        
lista_apel : NR
           | lista_apel ',' NR
           ;
%%
void yyerror(char * s){
printf("eroare: %s la linia:%d\n",s,yylineno);
}

int main(int argc, char** argv){
yyin=fopen(argv[1],"r");
yyparse();
} 