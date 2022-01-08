%{
#include<string.h>
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
	 int boolVal;
	 int array_index;
};

struct variable {
     char *name;
     char *type;
     union value val;
	 int isConst;
	 int hasVal;
	 int scope;
} vars[100];

struct functions {
    char *name;
    char *type;
	int nrArg;
	char *argNames[100];
	char *argTypes[100];
}funcs[100];

struct customtype {
	char *name;
	int noFields;
	char *fieldNames;
	char *fieldTypes[100];
};

int noVars = 0;

int insertVar(char *name, char *type);

int existsVar(char *s);

%}
%union {
int intval;
char* strval;
}

%token ID
%token NR
%token <customtype> CUSTOMTYPE
%token TYPE MAIN RTR ASSIGN IF FOR ELSE WHILE CONST OR AND EQ GEQ LEQ NOT NEQ
%type <strval> ID TYPE type_ CONST
%start program
%left AND OR
%left NOT
%left EQ NEQ GEQ LEQ G S
%left '+' '-'
%left '*' '/'
%left '('
%%

program : declarations_global functions mainblock {printf("program corect sintactic\n");}
		;

// Declaratii
declarations_global : declarations_global declare ';'
					| declare ';'
					;

declare   : TYPE ID {if(insertVar($2,$1) == 2) {char *msg; strcpy(msg,"Variable "); strcat(msg,$2); strcat(msg," already defined"); yyerror(msg);}}
		  | CONST TYPE ID ASSIGN 
		  | TYPE ID '(' declare_list ')'
		  | TYPE ID '('  ')'
		  ;

declare_list : declare_list ',' TYPE ID
			 | TYPE ID
		     ;
custom_type : CUSTOMTYPE ID '{' declarations_global '}'
			| CONST CUSTOMTYPE ID '{' declarations_global '}'

// Functii
functions : function
		  | functions function 
		  ;
function : TYPE ID '(' declare_list ')' '{' statements '}'
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
		  | asigments
	      | ID '(' param_list ')'
		  | IF '(' bool_expresion ')' block
		  | IF '(' bool_expresion ')' block ELSE block
		  | FOR '(' for_dec ';' bool_expresion ';' for_exp ')' block
		  | WHILE '(' bool_expresion ')' block
		  | returns
		  ;
asigments : ID ASSIGN ID 
		  | ID ASSIGN NR 
		  | ID ASSIGN statement 
		  | ID ASSIGN expresion
		  ;
param_list : param_list ',' ID
		   | param_list ',' NR
		   | ID '(' ')'
		   | ID '(' param_list ')'
		   | ID
		   | NR
		   ;
			  
bool_expresion : '(' bool_expresion ')'
			   | NOT bool_expresion
			   |  bool_expresion AND bool_expresion
			   | bool_expresion OR bool_expresion
			   | bool_expresion EQ bool_expresion
			   | bool_expresion GEQ bool_expresion
			   | bool_expresion LEQ bool_expresion
			   | bool_expresion S bool_expresion
			   | bool_expresion G bool_expresion
			   | bool_expresion ASSIGN bool_expresion
			   | expresion
			   ;

for_dec : declare
		| ID ASSIGN ID
		| ID ASSIGN NR
		;
for_exp : ID ASSIGN expresion
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
    | ID '(' param_list ')'
    | ID '('  ')'
    ;

%%
	
void yyerror(char * s){
printf("Error: %s at line:%d\n",s,yylineno);
}
int main(int argc, char** argv){
	yyin=fopen(argv[1],"r");
	yyparse();
} 

int insertVar(char *name, char *type) {
     int i = 0;
     for(i = 0; i < noVars; i++) {
          if(strcmp(vars[i].name, name) == 0)
               return 2;
     }

	 vars[noVars].name = name;
	 vars[noVars].type = type;
     //vars[noVars]. = val;
     if(strncmp(type,"const",5) == 0)
		 vars[noVars].isConst = 1;
	 else
		 vars[noVars].isConst = 0;
	 vars[noVars].hasVal = 0;
	 
	 printf("Variable type : %s, name: %s, isConst %d, hasVal %d\n",vars[noVars].type,vars[noVars].name,vars[noVars].isConst,vars[noVars].hasVal);
	 
     noVars++;
     return 0;
}

int existsVar(char *s) {
     int i = 0;
     for(i = 0; i < noVars; i++) {
          if(strcmp(s, vars[i].name) == 0)
               return i;
     }

     return -1;
}
