%{
#include<string.h>
#include <stdio.h>
#include<stdlib.h>
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

int insertVar(char *name, char *type, union value val,int scope);
int existsVar(char *s);
void printSymbolTabel();

%}
%union {
int intval;
char* strval;
}

%token ID
%token NR
%token <customtype> CUSTOMTYPE
%token TYPE MAIN STR RTR ASSIGN IF FOR ELSE WHILE CONST OR AND EQ GEQ LEQ NOT NEQ 
%type <strval> ID TYPE CONST STR type_
%type <intval> NR
%start program
%left AND OR
%left NOT
%left EQ NEQ GEQ LEQ G S
%left '+' '-'
%left '*' '/'
%left '('
%%

program : declarations_global   {printf("program corect sintactic\n");}
		;

// Declaratii
declarations_global : declarations_global declare ';'
					| declare ';'
					;

declare   : type_ ID 
				{
					union value x;  x.intVal = -1; 
					char msg[100]; strcpy(msg,"Variable "); 
					int err = insertVar($2,$1,x,0);
					if( err == 2) 
					{
						strcat(msg,$2); 
						strcat(msg," already defined"); 
						yyerror(msg);
					}
				}
		  | type_ ID ASSIGN NR 

		  | type_ ID ASSIGN ID
			  
		  | type_ ID ASSIGN '\"' STR '\"' 
			
		  ;

type_ : TYPE { $$ = $1;}
	  | CONST TYPE {strcat($1," "); strcat($1,$2); $$ = $1;}
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

declare_list : declare_list ',' TYPE ID
			 | TYPE ID
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
	printSymbolTabel();
} 

int insertVar(char *name, char *type, union value val, int scope) {
     int i = 0;
     for(i = 0; i < noVars; i++) {
          if(strcmp(vars[i].name, name) == 0)
               return 2;
     }

	 vars[noVars].name = name;
	 vars[noVars].type = type;
	 
	 if(val.intVal == -1)
		 vars[noVars].hasVal = 0;
	 else
	 {
		 vars[noVars].hasVal = 1;
		 vars[noVars].val = val;
	 }
     if(strncmp(type,"const",5) == 0){
		 vars[noVars].isConst = 1;
		 strcpy(vars[noVars].type,vars[noVars].type+6);
	 }
	 else
		 vars[noVars].isConst = 0;
	 vars[noVars].scope = scope;
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

void printSymbolTabel()
{
	FILE *file;
	file = fopen("SymbolTable.txt","w");
	int i;
	fprintf(file,"------------------------------\n");
	fprintf(file,"---------SYMBOL TABLE---------\n");
	fprintf(file,"------------------------------\n");
	for(i = 0; i < noVars; i++)
	{
		char constant[10];
		char scope[10];
		if(vars[i].isConst == 1)
			strcpy(constant,"Yes");
		else
			strcpy(constant,"No");
		if(vars[i].scope == 0)
			strcpy(scope,"global");
		if(vars[i].hasVal == 1)
		{
			if(strcmp(vars[i].type,"int") == 0)
			fprintf(file,"Type: [%s]    Name: [%s],   Const: [%s],   Value: [%d]   , Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.intVal,scope);
		}
		else
			fprintf(file,"Type: [%s]    Name: [%s],   Const: [%s],   Scope: [%s]\n",vars[i].type,vars[i].name,constant,scope);		
	}
	fclose(file);
}

