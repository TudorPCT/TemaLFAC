%{
#include<string.h>
#include <stdio.h>
#include<stdlib.h>
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(char *s);

int scope = 1;

union value {
     int intVal;
     float floatVal;
     char strVal[101];
     char charVal;
	 int boolVal;
};

struct variable {
     char *name;
     char *type;
     union value val;
	 int isConst;
	 int hasVal;
	 int scope;
} vars[100];

struct arrays{
	int isConst;
	int scope;
	int noElem;
	int maxElem;
	char *type;
	char *name;
	union value val[100];
}arr[100];

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
	struct variable fields[100];
	struct functions methods[100];
};

int noVars = 0;
int noArr = 0;

int insertVar(char *name, char *type, union value val);
void insertarray(char *type, char *name, int maxElem);
void assignVar(char* type_, char *id1, char* id2);
int existsVar(char *s);
void printSymbolTabel();

%}
%union {
int intval;
char charval;
char* strval;
float floatval;
}

%token ID
%token NR NRF
%token <customtype> CUSTOMTYPE
%token TYPE MAIN STR RTR ASSIGN IF FOR ELSE WHILE CONST OR AND EQ GEQ LEQ NOT NEQ CH FS DEC
%type <strval> ID TYPE CONST STR type_
%type <intval> NR
%type <floatval> NRF
%type <charval> CH
%start program
%left AND OR
%left NOT
%left EQ NEQ GEQ LEQ G S
%left '+' '-'
%left '*' '/'
%left '('
%%

program : DEC declarations_global functions mainblock {printf("program corect sintactic\n");}	
		;

// Declaratii
declarations_global : declare ';' declarations_global
					| FS {scope++;}
					| MAIN {scope = 0;}
					;

declare   : type_ ID 
				{
					union value x;  x.intVal = -1; 
					insertVar($2,$1,x);
				}
		  | type_ ID ASSIGN NR 
		  		{
					union value x;  
					if(strcmp($1,"float")  == 0|| strcmp($1,"const float") == 0)
						x.floatVal = $4;
					else
						x.intVal = $4; 
					insertVar($2,$1,x);
				}
	  	  | type_ ID ASSIGN NRF
	  		  	{
					printf("%s",$2);
	  				union value x;  
	  				x.floatVal = $4;
	  				insertVar($2,$1,x);
	  			}
		  | type_ ID ASSIGN '\"' CH '\"'
		  		{
					union value x;
					if(strcmp($1,"char")  == 0|| strcmp($1,"const char") == 0){
						x.charVal = $5;
						insertVar($2,$1,x);
					}
					else
					{
						char msg[100];
						sprintf(msg,"Type %s doesn't accept char'",$1);
						yyerror(msg);
					} 
		  	  	}
		  | type_ ID ASSIGN ID
		  		{		  			
					assignVar($1,$2,$4);
			  	}
		  | type_ ID '[' NR ']' 
		  		{
					insertarray($1,$2,$4);
		  	  	}
		  | type_ ID ASSIGN '\"' STR '\"' 
			
		  ;

type_ : TYPE { $$ = $1;}
	  | CONST TYPE {strcat($1," "); strcat($1,$2); $$ = $1;}
	;

custom_type : CUSTOMTYPE ID '{' declarations_global '}'
			| CONST CUSTOMTYPE ID '{' declarations_global '}'

// Functii
functions : function functions {scope++;}
		  | MAIN {scope = 0;}
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

mainblock : '{' statements '}'
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
	printf("Error at line: %d : %s\n",yylineno,s);
}
int main(int argc, char** argv){
	yyin=fopen(argv[1],"r");
	yyparse();
	printSymbolTabel();
} 

int insertVar(char *name, char *type, union value val) {
     int i = 0;
	 char msg[100];
     for(i = 0; i < noVars; i++) {
          if(strcmp(vars[i].name, name) == 0)
          {
			  sprintf(msg,"Variable \'%s\' already exist",name);
			  yyerror(msg);
			  return 2;
		  }
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

void insertarray(char *type, char *name, int maxElem)
{
   	 int i = 0;
 	 char msg[100];
   	 for(i = 0; i < noArr; i++) {
      	if(strcmp(arr[i].name, name) == 0)
        {
			  sprintf(msg,"Array \'%s\' already exist",name);
			  yyerror(msg);
			  return;
	 	 }
   	  }
	  arr[noArr].scope = scope;
	 arr[noArr].name = name;
	 arr[noArr].type = type;
	 arr[noArr].noElem = 0;
	 arr[noArr].maxElem = maxElem;
	 
	 if(strncmp(arr[noArr].type,"const",5) == 0)
		 strcpy(arr[noArr].type,arr[noArr].type+6);
	 arr[noArr].isConst = 1;
    noArr++;
}

int existsVar(char *s) {
     int i = 0;
     for(i = 0; i < noVars; i++) {
          if(strcmp(s, vars[i].name) == 0)
               return i;
     }

     return -1;
}

void assignVar(char *type_, char *id1, char *id2)
{
	union value x;  
	char msg[100];
	int i = existsVar(id2);
	if(i == -1)
	{
		sprintf(msg,"Variable %s doesn't exist",id2);
		yyerror(msg);
	}
	else
	{ 	
		if(strcmp(id1,vars[i].type) != 0)
		{
			sprintf(msg,"Variable %s has not same type with variable %s",id1,id2);
			yyerror(msg);
		}
		else
		{
			x = vars[i].val; 
			strcpy(msg,"Variable "); 
		    insertVar(id1,type_,x);
		}
	}
}

void printSymbolTabel()
{
	FILE *file;
	file = fopen("SymbolTable.txt","w");
	int i;
	fprintf(file,"--------------------------------------------------------------------\n");
	fprintf(file,"----------------------------SYMBOL TABLE----------------------------\n");
	fprintf(file,"--------------------------------------------------------------------\n");

	for(i = 0; i < noVars; i++)
	{
		char constant[10];
		char scopes[10];
		if(vars[i].isConst == 1)
			strcpy(constant,"Yes");
		else
			strcpy(constant,"No");
		if(vars[i].scope == 0)
			strcpy(scopes,"main");
		else if(vars[i].scope == 1)
			strcpy(scopes,"global");
		else
			strcpy(scopes,"function");
		if(vars[i].hasVal == 1)
		{
			if(strcmp(vars[i].type,"int") == 0)
				fprintf(file,"Type: [%s]      Name: [%s],   Const: [%s].    Value: [%d]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.intVal,scopes);
			else if(strcmp(vars[i].type,"float") == 0)
				fprintf(file,"Type: [%s]    Name: [%s]   Const: [%s]   Value: [%f]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.floatVal,scopes);
			else if(strcmp(vars[i].type,"bool") == 0){
				char b[6];
				if(vars[i].val.boolVal == 1)
					strcpy(b,"true");
				else
					strcpy(b,"false");
				fprintf(file,"Type: [%s]     Name: [%s]   Const: [%s]   Value: [%s]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,b,scopes);
			}
		}
		else
			fprintf(file,"Type: [%s]     Name: [%s]   Const: [%s]   Scope: [%s]\n",vars[i].type,vars[i].name,constant,scopes);		
	}
	for(i = 0; i < noArr; i++)
	{
		char constant[10];
		if(arr[i].isConst == 1)
			strcpy(constant,"Yes");
		else
			strcpy(constant,"No");
		char scopes[10];
		if(arr[i].scope == 1)
			strcpy(scopes,"global");
		else if(arr[i].scope == 0)
			strcpy(scopes,"main");
		else
			strcpy(scopes,"function");
		fprintf(file,"Type: [%s]      Name: [%s]     Const: [%s]   No of elements: [%d] Max no of elements: [%d]  Scope: [%s]\n",arr[i].type,arr[i].name,constant,arr[i].noElem,arr[i].maxElem,scopes);
		
	}
	fclose(file);
}

