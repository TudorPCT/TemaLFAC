%{
#include <stdio.h>
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(char *s);

union value {
     int intVal;
     float floatVal;
     char strVal[101];
     char charVal;
};

struct variable {
     char *name;
     char *type;
     int val;
	 int constant;
	 int scope;
} vars[100];

int noVars = 0;

%}
%token ID TYPE ASSIGN MAIN NR CUSTOMTYPE RTR IF FOR ELSE WHILE CONST OR AND EQ GEQ LEQ
%start program
%%

program : declarations_global functions mainblock {printf("program corect sintactic\n");}
		;

// Declaratii
declarations_global : declarations_global declare ';'
					| declare ';'
					;
declare : TYPE variables 
		| CONST TYPE variables
		| custom_type
		;
variables : ID
		  | ID ',' variables
		  | ID '(' declare ')'
		  | ID '('  ')'
		  | ID ASSIGN ID
		  | ID ASSIGN NR
		  ;
custom_type : CUSTOMTYPE ID '{' declarations_global '}'

// Functii
functions : function
		  | functions function 
		  ;
function : TYPE ID '(' declare ')' '{' statements '}'
		 | TYPE ID '(' ')' '{' statements '}'
		 ;

block : '{' statements '}'
	  | statement
	  ;
statements : statements statement ';'
		   | statement ';'
		   | ';'
	       ;
statement : declare
		  | ID ASSIGN ID 
		  | ID ASSIGN NR 
		  | expresion
	      | ID '(' param_list ')'
		  | IF '(' bool_expresion ')' block
		  | IF '(' bool_expresion ')' block ELSE block
		  | FOR '(' for_dec ';' bool_expresion ';' for_exp ')' block
		  | WHILE '(' bool_expresion ')' block
		  | returns
		  ;
param_list : param_list ',' ID
		   | param_list ',' NR
		   | ID '(' ')'
		   | ID '(' param_list ')'
		   | ID
		   | NR
		   ;
			  
bool_expresion : '(' bool_expresion ')'
			   | '!' bool_expresion
			   |  bool_expresion AND bool_expresion
			   | bool_expresion OR bool_expresion
			   | bool_expresion EQ bool_expresion
			   | bool_expresion GEQ bool_expresion
			   | bool_expresion LEQ bool_expresion
			   | bool_expresion '<' bool_expresion
			   | bool_expresion '>' bool_expresion
			   | bool_expresion ASSIGN bool_expresion
			   | expresion
			   ;

for_dec : declare
		| ID ASSIGN ID
		| ID ASSIGN NR
		;
for_exp : ID ASSIGN exp
		| ID '+' '+'
		| | ID '-' '-'
		;

returns : RTR 
	    | RTR NR
	    | RTR ID 
		;
		

// Main

mainblock : TYPE MAIN '(' ')' '{' statements '}'
		  ;


//Operations
expresion : '(' expresion ')'
		  | exp 
		  ;
exp : exp '+' exp    
    | exp '-' exp   
    | exp '*' exp 
    | exp '/' exp    
    | exp '^' exp    
    | NR
	| ID
    ;

string : string '+' string
       | string '^' exp
	   | string '%' string
	;

%%
	
void yyerror(char * s){
printf("eroare: %s la linia:%d\n",s,yylineno);
}
int main(int argc, char** argv){
	yyin=fopen(argv[1],"r");
	yyparse();
} 
