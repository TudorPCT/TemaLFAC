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
	 int const;
	 int scope;
} vars[100];

int noVars = 0;

%}
%token ID TYPE ASSIGN MAIN NR CUSTOMTYPE RTR IF FOR ELSE WHILE
%start program
%%

program : declarations_global functions main {printf("program corect sintactic\n");}
		;

// Declaratii
declarations_global : declare ';' declarations_global
					| function declarations_global
					| custom_type ';' declarations_global
					|
					;
declare : TYPE variables 
		| CONST TYPE variables
		|
		;
variables : ID
		  | ID ',' variables
		  | ID '(' declare ')'
		  | ID ASSIGN ID
		  | ID ASSIGN NR
		  ;


// Functii
functions : function functions
		  ;
function : TYPE ID '(' declare ')' '{' block '}'
		 ;
block : '{' statements '}'
	  | statements
	  ;
statements : statement ';' statements
		   | statement
		   | 
	       ;
statement : declare
		  | ID ASSIGN ID 
		  | ID ASSIGN NR  
		  | exp
	      | ID '(' declare ')'
		  | IF '(' bool_expresion ')' block
		  | IF '(' bool_expresion ')' block ELSE block
		  | FOR '(' for_dec ';' bool_expresion ';' exp ')' block
		  | WHILE '(' bool_expresion ')' block
		  | returns
		  ;
returns : RTR ';'
	    | RTR NR ';'
	    | RTR ID ';'
		;
		

// Main

	
mainbloc : TYPE MAIN '(' ')' block
	;


//Operations
exp : exp '+' exp    {$$=($1+$3);}
    | exp '-' exp    {$$=($1-$3);}
    | exp '*' exp    {$$=($1*$3);}
    | exp '/' exp    {$$=($1/$3);}
    | '!'exp         {$$=0-$2;}
    | exp '^' exp    {$$=pow($1,$3)}
    |NR
    ;

string : string '+' string   { char* s=strdup($1);  strcat(s,$3); $$=s;}
        |string '^' exp      { if($3==0)         //primele exp caractere din string 
	                       $$='\0';
			       else 
			         { char *s=strdup(%1); 
			           for(int i=1;i<=$3;++i)
			           s=strcat(s,$1);
			           $$=s;}
			    }
	|string '%' string  { char* s="";       
	                      char* s2=strdup($1);
			      char* s3=strdup($3);
			      int i=0;
			      while(s2[i]!='\0' && s3[i]!='\0')
			      {
			         strncat(s,s2[i],1);
				 strncat(s,s3[i],1);
				 ++i;
			      }
			      $$=s;
			    }
	;

%%
void yyerror(char * s){
printf("eroare: %s la linia:%d\n",s,yylineno);
}
int main(int argc, char** argv){
	yyin=fopen(argv[1],"r");
	yyparse();
} 
		   
	   

