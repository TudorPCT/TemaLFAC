%{
#include<string.h>
#include <stdio.h>
#include<stdlib.h>
#include<math.h>
	
extern FILE* yyin;
extern char* yytext;
extern int yylineno;
int yylex();
void yyerror(char *s);
int scope = 1;
int yyr = 0;

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
	 union value arr[100];
 	 int noElem;
 	 int maxElem;
} vars[100];


struct functions {
    char *name;
    char *type;
	struct arguments *args;
	int method;
	int defined;
}funcs[100];

struct customtype {
	char *name;
	struct arguments *fields;
}ct[100];

struct node {
	int type;
	union value var;
	struct node *left;
	struct node *right;
};

struct arguments {
	int noArgs;
	char *argNames[100];
	char *argTypes[100];
	int argConsts[100];
};

struct prints{
	int noPrn;
	char *str[100];
	int results[100];
}prn;

int noVars = 0;
int noCT = 0;
int noFuncs = 0;

int insertVar(char *name, char *type, int maxElem);
void assign(int type, union value id1, union value id2, int index1, int index2);
struct node* buildAST(union value root,struct node* left,struct node* right,int type);
int evalAST(struct node* AST);
int existsVar(char *s);
struct arguments *addArgs(struct arguments *args, char *type_, char *name);
void insertFunc(char *type_, char *name, struct arguments *args, int method, int defined);
int existsFunc(char *type_, char *name, struct arguments *args, int tc);
void printSymbolTabel();
void printFunctionTabel();

%}
%union {
int intval;
char charval;
char* strval;
float floatval;
struct node *astval;
struct arguments *argval;
}

%token ID
%token NR NRF
%token <customtype> CUSTOMTYPE
%token TYPE MAIN STR RTR ASSIGN IF FOR ELSE WHILE CONST OR AND EQ GEQ LEQ NOT NEQ CH FS DEC PRT 
%type <strval> ID TYPE CONST STR type_ function_call args_ returns_ statement statements
%type <intval> NR 
%type <floatval> NRF
%type <charval> CH
%type <astval> exp
%type<argval> declare_list arg_list dec_
%start program
%left AND OR
%left NOT
%left EQ NEQ GEQ LEQ G S
%left '+' '-'
%left '*' '/'
%left '^'
%left '('
%%

program : DEC declarations_global functions mainblock {printf("Program is syntactically correct\n");}	
		;

// Declaratii
declarations_global : declare ';' declarations_global
					| FS {scope=3;}
					| MAIN {scope = 0;}
					;


declare   : type_ ID 
				{
					char msg[100];
					if(strncmp($1,"const",5) == 0) 
					{
						sprintf(msg,"Const variable \'%s\' needs to be initialised",$2);
						yyerror(msg);
					} else {
						insertVar($2,$1,0);
						vars[noVars-1].isConst = 0;
					}
				}	
		  | type_ ID ASSIGN NR 
		  		{
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					union value id1,id2;
					strcpy(id1.strVal, $2);
					insertVar($2,$1,0);
					if(strcmp($1,"float")  == 0 || strcmp($1,"const float") == 0) {
						id2.floatVal = $4;
						assign(2,id1,id2,0,0);
					}
					else{
						id2.intVal = $4; 
						assign(1,id1,id2,0,0);
					}
					vars[noVars-1].isConst = x;
				}
	  	  | type_ ID ASSIGN NRF
	  		  	{
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					union value id1,id2;
					strcpy(id1.strVal, $2);
	  				id2.floatVal = $4;
	  				insertVar($2,$1,0);
					assign(2,id1,id2,0,0);
					vars[noVars-1].isConst = x;
	  			}
	   	  | type_ ID ASSIGN CH 
	   		    {
	   				int x;
	  				if(strncmp($1,"const",5) == 0) x = 1;
	 				else x = 0;
	   				union value id1,id2;
	  				strcpy(id1.strVal, $2);
	   				insertVar($2,$1,0);
	   				id2.charVal = $4;
	   				assign(3,id1,id2,0,0);
	   				vars[noVars-1].isConst = x;
	   	  	  	}
		  | type_ ID ASSIGN STR 
		 	    {
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					union value id1,id2;
					strcpy(id1.strVal, $2);
					insertVar($2,$1,strlen($4));
					strcpy(id2.strVal, $4);
					assign(4,id1,id2,0,0);
					vars[noVars-1].isConst = x;
		  	  	}

		  | type_ ID ASSIGN ID
  				{	
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					union value id1,id2;
					strcpy(id1.strVal, $2);
					strcpy(id2.strVal, $4);
					insertVar($2,$1,0);
					assign(5,id1,id2,0,0);
					vars[noVars-1].isConst = x;
  	 	   }
		  | type_ ID '[' NR ']' 
		  		{
					int x;
					char msg[100];
					if(strncmp($1,"const",5) == 0) {
						sprintf(msg,"Const variable \'%s\' needs to be initialised",$2);
						yyerror(msg);
					} else {
						insertVar($2,$1,$4);
						vars[noVars-1].isConst = x;
					}
		  	  	}
		  ;

type_ : TYPE { $$ = $1;}
	  | CONST TYPE {strcat($1," "); strcat($1,$2); $$ = $1;}
	;

// Functii
functions : function functions
		  | MAIN {scope = 0;}
		  ;

function : TYPE ID '(' declare_list ')' '{' statements '}' 
			{
				insertFunc($1,$2,$4,scope%2,1);
				if(($7 == NULL && strcmp($1,"void") != 0) || strcmp($1,$7) != 0)
				{
					char msg[100];
					sprintf(msg,"Return type value doen't match the function type");
					yyerror(msg);
				}	
						
			}
		 | TYPE ID '(' ')' '{' statements '}' 
		 {
			scope++;
			struct arguments *arg = malloc(sizeof(struct arguments));
			arg->noArgs = 0;
			insertFunc($1,$2,arg,scope%2,1);
			
		 }
		 | custom_type ID ';'
	     | custom_type ';'
		 ;

declare_list : declare_list ',' type_ ID
				{
					$$ = addArgs($1,$3,$4);
				}
			 | type_ ID
				{
					struct arguments*  args = malloc(sizeof(struct arguments));
					args->noArgs = 0;
					$$ = addArgs(args,$1,$2);
				}
			 | type_ ID '[' ']'
				{
					struct arguments*  args = malloc(sizeof(struct arguments));
					args->noArgs = 0;
					$$ = addArgs(args,$1,$2);
				}
		     ;

custom_type : CUSTOMTYPE ID '{' dec_ ';' '}'   
			 	{
			 		ct[noCT].name = $2;
			 		ct[noCT].fields = $4;
					noCT++;
	 			}

dec_ : dec_ ';' type_ ID  
		  	{
	 			$$ = addArgs($1,$3,$4);
				if(scope % 2 == 1)
					scope++;
				insertVar($4,$3,0);
				scope++;
			}
	 | type_ ID 
			{
				if(scope % 2 == 1)
					scope++;
				struct arguments*  args = malloc(sizeof(struct arguments));
		 		args->noArgs = 0;
		 		$$ = addArgs(args,$1,$2);
		 		insertVar($2,$1,0);
				scope++;
		 	}
	 | type_ ID '[' NR ']' 
		 	{
				if(scope % 2 == 1)
					scope++;
		 		struct arguments*  args = malloc(sizeof(struct arguments));
		 		args->noArgs = 0;
		 		$$ = addArgs(args,$1,$2);
		 		insertVar($2,$1,$4);
				scope++;
		 	}
	 ;
				 
function_call : ID '('')' 
				{
					char msg[100];
					struct arguments*  args = malloc(sizeof(struct arguments));
					args->noArgs = 0;
					int i = existsFunc(NULL,$1,args,0);
					if(i == -1)
					{
						sprintf(msg,"Function called \'%s\' couldn't be found",$1);
						yyerror(msg);
					}
					else
						$$ = funcs[i].type;
				}	
              | ID '(' arg_list ')' 
			  	{
					char msg[100];
					int i = existsFunc(NULL,$1,$3,0);
					if(i == -1)
					{
						sprintf(msg,"Function called \'%s\' couldn't be found",$1);
						yyerror(msg);
					}
					else
						$$ = funcs[i].type;
			  	}
			  ;

arg_list : arg_list ',' args_
			{
				$$ = addArgs($1,$3,NULL);
			}
		 | args_
			{
				struct arguments*  args = malloc(sizeof(struct arguments));
				args->noArgs = 0;
				$$ = addArgs(args,$1,"");
			}
		 ;
args_ : ID 	{char msg[100];int i = existsVar($1); if(i == -1){ sprintf(msg,"Variable %s doesn't exist",$1); yyerror(msg);}else {$$ = vars[i].type;} }
	  | NR	{$$ = "int";}
	  | NRF	{$$ = "float";}
	  | CH	{$$ = "char";}
	  | STR {$$ = "string";}
	  | function_call	{$$ = $1;}
	  | exp	{$$ = "int";}
	  ;
		

block : '{' statements '}'
	  | statement 
	  ;
statements : statements statement ';' {if($1 == NULL) $$ = $2;}
		   | statement ';'{$$ = $1;}
		   | ';'
	       ;
statement : declare {$$ = NULL;}
		  | asigments {$$ = NULL;}
		  | function_call {$$ = NULL;}
		  | IF '(' bool_expresion ')' block {$$ = NULL;}
		  | IF '(' bool_expresion ')' block ELSE block {$$ = NULL;}
		  | FOR '(' for_dec ';' bool_expresion ';' for_exp ')' block {$$ = NULL;}
		  | WHILE '(' bool_expresion ')' block {$$ = NULL;}
		  | PRT '('  STR ',' exp ')' {$$ = NULL;prn.str[prn.noPrn] = $3; prn.results[prn.noPrn++]=evalAST($5);}
		  | returns_ {$$ = $1;}
		  ;
		  
asigments : ID ASSIGN ID {union value id1,id2; strcpy(id1.strVal, $1); strcpy(id2.strVal, $3); assign(5,id1,id2,0,0);}
		  | ID ASSIGN NR {union value id1,id2; strcpy(id1.strVal, $1); id2.intVal = $3; assign(1,id1,id2,0,0);}
		  | ID ASSIGN NRF {union value id1,id2; strcpy(id1.strVal, $1); id2.floatVal = $3; assign(2,id1,id2,0,0);}
		  | ID ASSIGN CH {union value id1,id2; strcpy(id1.strVal, $1); id2.charVal = $3; assign(3,id1,id2,0,0);}
		  | ID ASSIGN STR {union value id1,id2; strcpy(id1.strVal, $1); strcpy(id2.strVal, $3); assign(4,id1,id2,0,0);}
		  | ID ASSIGN exp {union value id1,id2; strcpy(id1.strVal, $1); id2.intVal = evalAST($3); assign(1,id1,id2,0,0);}
		  | ID ASSIGN ID '[' NR ']' {union value id1,id2; strcpy(id1.strVal, $1); strcpy(id2.strVal, $3); assign(6,id1,id2,0,$5);}
		  | ID '[' NR ']' ASSIGN ID {union value id1,id2; strcpy(id1.strVal, $1); strcpy(id2.strVal, $6); assign(7,id1,id2,$3,0);}
		  | ID '[' NR ']' ASSIGN ID '[' NR ']' {union value id1,id2; strcpy(id1.strVal, $1);  strcpy(id2.strVal, $8); assign(6,id1,id2,$3,$8);}
		  | ID '[' NR ']' ASSIGN NR {union value id1,id2; strcpy(id1.strVal, $1); id2.intVal = $6; assign(9,id1,id2,$3,0);}
		  | ID '[' NR ']' ASSIGN NRF {union value id1,id2; strcpy(id1.strVal, $1); id2.intVal = $6; assign(10,id1,id2,$3,0);}
		  | ID '[' NR ']' ASSIGN CH {union value id1,id2; strcpy(id1.strVal, $1); id2.intVal = $6; assign(11,id1,id2,$3,0);}
		  | ID '[' NR ']' ASSIGN exp {union value id1,id2; strcpy(id1.strVal, $1); id2.intVal = evalAST($6); assign(9,id1,id2,$3,0);}
		  
		  ;

bool_expresion : '(' bool_expresion ')'
			   | NOT bool_expresion
			   | bool_expresion AND bool_expresion
			   | bool_expresion OR bool_expresion
			   | bool_expresion EQ bool_expresion
			   | bool_expresion NEQ bool_expresion
			   | bool_expresion GEQ bool_expresion
			   | bool_expresion LEQ bool_expresion
			   | bool_expresion S bool_expresion
			   | bool_expresion G bool_expresion
			   | bool_expresion '+' bool_expresion
			   | bool_expresion '-' bool_expresion
			   | bool_expresion '/' bool_expresion
		       | bool_expresion '*' bool_expresion
		       | bool_expresion '^' bool_expresion
			   | ID
			   | NR
			   ;

for_dec : declare
		| asigments
		;
for_exp : ID ASSIGN exp
		| ID '+' '+'
		| | ID '-' '-'
		;

returns_ : RTR {$$ = "void";}
	    | RTR NR {$$ = "int";}
		| RTR NRF {$$ = "float";}
		| RTR STR {$$ = "string";}
		| RTR CH {$$ = "char";}	
	    | RTR ID {char msg[100]; int i = existsVar($2); if(i == -1) {sprintf(msg,"Variable \'%s\' not found\n"); yyerror(msg);} else $$ = vars[i].type;}
		;
		

// Main

mainblock : '{' statements '}'
		  ;


//Operations

exp : '(' exp ')'  		 {$$ = $2;}
	| exp '+' exp   	 {union value x; x.charVal = $<charval>2; $$ = buildAST(x,$1,$3,1);}
    | exp '-' exp   	 {union value x; x.charVal = $<charval>2; $$ = buildAST(x,$1,$3,2);}
    | exp '*' exp  		 {union value x; x.charVal = $<charval>2; $$ = buildAST(x,$1,$3,3);}
    | exp '/' exp   	 {union value x; x.charVal = $<charval>2; $$ = buildAST(x,$1,$3,4);}
    | exp '^' exp     	 {union value x; x.charVal = $<charval>2; $$ = buildAST(x,$1,$3,5);}
    | NR				 {union value x; x.intVal = $1; $$ = buildAST(x,NULL,NULL,6);}
	| ID				 {union value x; strcpy(x.strVal, $1); $$ = buildAST(x,NULL,NULL,7);}
    ;

%%
	
void yyerror(char * s){
	printf("Error at line: %d : %s\n",yylineno,s);
	yyr = 1;
}
int main(int argc, char** argv){
	yyin=fopen(argv[1],"r");
	yyparse();
	int i;
	if(yyr == 0){
		printf("Program semantically correct\n");
		for(i = 0; i < prn.noPrn; i++)
			printf("%s %d\n",prn.str[i],prn.results[i]);
	}
	printSymbolTabel();
	printFunctionTabel();
} 

int insertVar(char *name, char *type, int maxElem) {
     int i = 0;
	 char msg[100];
     for(i = 0; i < noVars; i++) {
          if(strcmp(vars[i].name, name) == 0 && ( (vars[i].scope == 1 && scope % 2 == 1) || vars[i].scope == scope))
          {
			  sprintf(msg,"Variable \'%s\' already exist",name);
			  yyerror(msg);
			  return 2;
		  }
     }
	 vars[noVars].name = name;
	 vars[noVars].type = type;
     if(strncmp(type,"const",5) == 0)
		 strcpy(vars[noVars].type,vars[noVars].type+6);
	 vars[noVars].isConst = 0;
	 vars[noVars].scope = scope;
	 vars[noVars].noElem = 0;
	 vars[noVars].maxElem = maxElem;
     noVars++;
	 return 0;
}


int existsVar(char *s) {
     int i = 0;
     for(i = 0; i < noVars; i++) {
          if(strcmp(s, vars[i].name) == 0 && (vars[i].scope == 1 || vars[i].scope == scope))
               return i;
     }

     return -1;
}

void assign(int type, union value id1, union value id2, int index1, int index2)
{
	union value x;  
	char msg[100];
	int j,i = existsVar(id1.strVal);
	if(i == -1)
	{
		sprintf(msg,"Variable \'%s\' doesn't exist",id1.strVal);
		yyerror(msg);
		return;
	}
	if(vars[i].isConst == 1)
	{
		sprintf(msg,"Variable \'%s\' is constant",vars[i].name);
		yyerror(msg);
		return;
	}
	vars[i].hasVal = 1;
	switch(type)
	{
		case 1:
			if(strcmp(vars[i].type,"float") == 0)
				vars[i].val.floatVal = id2.intVal;
			else
				vars[i].val.intVal = id2.intVal;
		break;
		case 2:
			if(strcmp(vars[i].type,"float") != 0)
			{
				sprintf(msg,"Can't assign a float value to variable \'%s\' of type %s",vars[i].name,vars[i].type);
				yyerror(msg);
				return;
			}
			vars[i].val.floatVal = id2.floatVal;
		break;
		case 3:
			if(strcmp(vars[i].type,"char") != 0){
				sprintf(msg,"Can't assign a char value to variable \'%s\' of type %s",vars[i].name,vars[i].type);
				yyerror(msg);
				return;
			}
			vars[i].val.charVal = id2.charVal;
		break;
		case 4:
			if(strcmp(vars[i].type,"string") != 0){
				sprintf(msg,"Can't assign a string to variable \'%s\' of type %s",vars[i].name,vars[i].type);
				yyerror(msg);
				return;
			}
			vars[i].noElem = strlen(id2.strVal);
			for(j = 0; j < vars[i].noElem; j++)
				vars[i].arr[j].charVal = id2.strVal[j];
			
		break;
		case 5:
			j = existsVar(id2.strVal);
			if(j == -1){
				sprintf(msg,"Variable \'%s\' doesn't exist",id2.strVal);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,vars[j].type) != 0){
				sprintf(msg,"Variable \'%s\' has not same type with variable %s",vars[i].type,vars[j].type);
				yyerror(msg);
			}
			else	vars[i].val  = vars[j].val;
		break;
		case 6:
			j = existsVar(id2.strVal);
			if(j == -1){
					sprintf(msg,"Variable \'%s\' doesn't exist",id2.strVal);
					yyerror(msg);
					return;
			}
			if(strcmp(vars[i].type,vars[j].type) != 0){
				sprintf(msg,"Variable \'%s\' has not same type with variable %s",vars[i].type,vars[j].type);
				yyerror(msg);
			}
			else	vars[i].val  = vars[j].arr[index2];
		break;
		case 7:
			j = existsVar(id2.strVal);
			if(j == -1){
				sprintf(msg,"Variable \'%s\' doesn't exist",id2.strVal);
				yyerror(msg);
				return;
			}
			if(vars[i].maxElem == 0)
			{
				sprintf(msg,"Variable \'%s\' is not an array",vars[i].name);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,vars[j].type) != 0){
				sprintf(msg,"Array \'%s\' has not same type with variable \'%s\'",vars[i].type,vars[j].type);
				yyerror(msg);
				return;
			}
			if(index1 > vars[i].maxElem){
				sprintf(msg,"Index given is higher than the array [%s] capacity",vars[i].name);
				yyerror(msg);
				return;
			}
			vars[i].arr[index1] = vars[j].val;
			if(index1 >= vars[i].noElem)
				vars[i].noElem = index1+1;
		break;
		case 8:
			j = existsVar(id2.strVal);
			if(j == -1){
				sprintf(msg,"Variable \'%s\' doesn't exist",id2.strVal);
				yyerror(msg);
				return;
			}
			if(vars[i].maxElem == 0)
			{
				sprintf(msg,"Variable \'%s\' is not an array",vars[i].name);
				yyerror(msg);
				return;
			}
			if(index1 > vars[i].maxElem){
				sprintf(msg,"Index given is higher than the array [%s] capacity",vars[i].name);
				yyerror(msg);
				return;
			}
			if(index2 > vars[j].maxElem){
				sprintf(msg,"Index given is higher than the array [%s] capacity",vars[j].name);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,vars[j].type) != 0){
				sprintf(msg,"Variable \'%s\' doesn't have the same type with variable %s",vars[i].type,vars[j].type);
				yyerror(msg);
			}
			else	vars[i].arr[index1] = vars[j].arr[index2];
			if(index1 >= vars[i].noElem)
				vars[i].noElem = index1+1;
		break;
		case 9:
			if(vars[i].maxElem == 0)
			{
				sprintf(msg,"Variable \'%s\' is not an array",vars[i].name);
				yyerror(msg);
				return;
			}	
			if(index1 > vars[i].maxElem){
				sprintf(msg,"Index given is higher than the array [%s] capacity",vars[i].name);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,"int") == 0)
				vars[i].arr[index1]  = id2;
			else if(strcmp(vars[i].type,"float") == 0)
				vars[i].arr[index1].floatVal  = id2.intVal;
			else{
				sprintf(msg,"Can't assign an integer to a %s type array",vars[i].type);
				yyerror(msg);
			}
			if(index1 >= vars[i].noElem)
				vars[i].noElem = index1+1;
		break;
		case 10:
			if(vars[i].maxElem == 0)
			{
				sprintf(msg,"Variable \'%s\' is not an array",vars[i].name);
				yyerror(msg);
				return;
			}	
			if(index1 > vars[i].maxElem){
				sprintf(msg,"Index given is higher than the array [%s] capacity",vars[i].name);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,"float") == 0)
				vars[i].arr[index1]  = id2;
			else{
				sprintf(msg,"Can't assign a float to a %s type array",vars[i].type);
				yyerror(msg);
			}
			if(index1 >= vars[i].noElem)
				vars[i].noElem = index1+1;
		break;
		case 11:
			if(vars[i].maxElem == 0)
			{
				sprintf(msg,"Variable \'%s\' is not an array",vars[i].name);
				yyerror(msg);
				return;
			}	
			if(index1 > vars[i].maxElem){
				sprintf(msg,"Index given is higher than the array [%s] capacity",vars[i].name);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,"string") == 0)
				vars[i].arr[index1]  = id2;
			else{
				sprintf(msg,"Can't assign a float to a %s type array",vars[i].type);
				yyerror(msg);
			}
			if(index1 >= vars[i].noElem)
				vars[i].noElem = index1+1;
		break;
	}
}

struct arguments *addArgs(struct arguments *args, char *type_, char *name)
{
	int i;
	char msg[100];
	if(name != NULL)
	{
		for(i = 0; i < args->noArgs; i++)
			if(strcmp(args->argNames[i],name) == 0)
			{
				sprintf(msg,"Argument \'%s\' already exist",name);
				yyerror(msg);
			  return NULL;
			}
	}
	if(strncmp(type_,"const",5) == 0){
		args->argConsts[args->noArgs] = 1;
		strcpy(type_,type_+6);
	}
	else
		args->argConsts[args->noArgs] = 0;
	args->argTypes[args->noArgs] = type_;
	args->argNames[args->noArgs] = name;
	args->noArgs++;
	return args;
}

void insertFunc(char *type_, char *name, struct arguments *args, int method, int defined)
{
	int i;
	char msg[100];
	if(existsFunc(type_,name,args,1) != -1)
	{
	  sprintf(msg,"Redefinion of function \'%s\' ", name);
	  yyerror(msg);
	  
	  return;
	}
	funcs[noFuncs].type = type_;
	funcs[noFuncs].name = name;
	funcs[noFuncs].args = args;
	funcs[noFuncs].method = method;
	funcs[noFuncs].defined = defined;
	noFuncs++;
}

int existsFunc(char *type_, char *name, struct arguments *args, int tc)
{
	int i = 0;
	for(i = 0; i < noFuncs; i++)
		if(strcmp(funcs[i].name,name) == 0)
		{
			int j = 0,x = 0;
			for(j = 0; j < funcs[i].args->noArgs && j < args->noArgs; j++){
				if(strcmp(funcs[i].args->argTypes[j],args->argTypes[j]) == 0)
					x++;
			}
			if(x == args->noArgs && funcs[i].args->noArgs == x)
				if(tc == 0 || (tc == 1 && strcmp(funcs[i].type,type_) == 0))
					return i;			
		}
	
	return -1;
}

struct node * buildAST(union value root,struct node *left,struct node *right,int type)
{ 
	if(type == 7)
	{
		int i = existsVar(root.strVal);
		if(i == -1)
		{
			char msg[100];
			sprintf(msg,"Variable \'%s\' not found",root.strVal);
			yyerror(msg);
			return NULL;
		} else if(strcmp(vars[i].type,"int") != 0 && strcmp(vars[i].type,"bool") != 0)
			root.intVal = 0;
	}
	struct node*  AST = malloc(sizeof(struct node));
	AST->var = root;
  	AST->type = type;
  	AST->left = left;
 	AST->right = right;
 	return AST;
}

int evalAST(struct node* AST)
{
	int leftval = 0;
	int rightval = 0;
	if(AST->left != NULL)
		leftval = evalAST(AST->left);
	if(AST->right != NULL)
		rightval = evalAST(AST->right);
	switch(AST->type)
	{
		case 1:
			return leftval + rightval;
		break;
		case 2:
			return leftval - rightval;
		break;
		case 3:
			return leftval * rightval;
		break;
		case 4:
			return leftval / rightval;
		break;
		case 5:
			return pow(leftval, rightval);
		break;
		case 6:
			return AST->var.intVal;
		break;
		case 7:
			return vars[existsVar(AST->var.strVal)].val.intVal;
		default :
			return 0;
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
		else if(vars[i].scope % 2 == 0)
			strcpy(scopes,"struct");
		else
			strcpy(scopes,"function");
		if(vars[i].maxElem == 0)
		{
			if(vars[i].hasVal == 1){
				if(strcmp(vars[i].type,"int") == 0)
					fprintf(file,"Type: [%s]      Name: [%s],   Const: [%s].    Value: [%d]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.intVal,scopes);
				else if(strcmp(vars[i].type,"char") == 0)
					fprintf(file,"Type: [%s]     Name: [%s],   Const: [%s].    Value: [%c]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.charVal,scopes);
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
			else fprintf(file,"Type: [%s]     Name: [%s]   Const: [%s]   Scope: [%s]\n",vars[i].type,vars[i].name,constant,scopes);		
		}
		else if(vars[i].maxElem != 0)
		{
			int j;
			fprintf(file,"Type: [%s]     Name: [%s]     Const: [%s]   No of elements: [%d] Max no of elements: [%d] Values: [ ",vars[i].type,vars[i].name,constant,vars[i].noElem,vars[i].maxElem);				for(j = 0; j < vars[i].noElem; j++)
			for(j = 0; j < vars[i].noElem; j++)
			{
				if(strcmp(vars[i].type,"int") == 0)
					fprintf(file,"%d",vars[i].arr[j].intVal);
				else if(strcmp(vars[i].type,"char") == 0)
					fprintf(file,"%c",vars[i].arr[j].charVal);
				else if(strcmp(vars[i].type,"float") == 0)
					fprintf(file,"%f",vars[i].arr[j].floatVal);
				else if(strcmp(vars[i].type,"string") == 0)
					fprintf(file,"%c",vars[i].arr[j].charVal);
				else if(strcmp(vars[i].type,"bool") == 0){
					char b[6];
					if(vars[i].val.boolVal == 1)
						strcpy(b,"true");
					else
						strcpy(b,"false");
					fprintf(file,"%s",b);
				}
				if(j != vars[i].noElem - 1 && strcmp(vars[i].type,"string") != 0)
					fprintf(file,", ");
			}
			fprintf(file," ]    Scope: [%s]\n",scopes);
		}
		else
			printf(file,"Type: [%s]      Name: [%s]     Const: [%s]   No of elements: [%d] Max no of elements: [%d]  Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].noElem,vars[i].maxElem,scopes);

	}

	fclose(file);
}


void printFunctionTabel()
{
	FILE *file;
	file = fopen("FunctionTable.txt","w");
	int i,j;
	fprintf(file,"----------------------------------------------------------------------\n");
	fprintf(file,"----------------------------FUNCTION TABLE----------------------------\n");
	fprintf(file,"----------------------------------------------------------------------\n");

	for(i = 0; i < noFuncs; i++)
	{
		char method[5];
		if(funcs[i].method == 1)
			strcpy(method,"No");
		else
			strcpy(method,"Yes");
		fprintf(file,"Return type: [%s]    Name: [%s]  Arguments: ",funcs[i].type,funcs[i].name);
		if(funcs[i].args == NULL)
			fprintf(file,"[No arguments]  Method: [%s]\n ",method);
		else{
			for(j = 0; j < funcs[i].args->noArgs - 1; j++)
				fprintf(file,"%s %s, ",funcs[i].args->argTypes[j],funcs[i].args->argNames[j]);
			fprintf(file,"%s %s   Method: [%s]\n",funcs[i].args->argTypes[j],funcs[i].args->argNames[j],method);
		}
	}
	
	fclose(file);
}
