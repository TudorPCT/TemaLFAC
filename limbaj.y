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

struct node {
	int type;
	union value var;
	struct node *left;
	struct node *right;
};

int noVars = 0;
int noArr = 0;

int insertVar(char *name, char *type);
void insertarray(char *type, char *name, int maxElem);
void assign(int type, union value id1, union value id2);
struct node* buildAST(union value root,struct node* left,struct node* right,int type);
int evalAST(struct node* AST);
int existsVar(char *s);
void printSymbolTabel();

%}
%union {
int intval;
char charval;
char* strval;
float floatval;
struct node *astval;
}

%token ID
%token NR NRF
%token <customtype> CUSTOMTYPE
%token TYPE MAIN STR RTR ASSIGN IF FOR ELSE WHILE CONST OR AND EQ GEQ LEQ NOT NEQ CH FS DEC PRT
%type <strval> ID TYPE CONST STR type_
%type <intval> NR
%type <floatval> NRF
%type <charval> CH
%type <astval> exp
%start program
%left AND OR
%left NOT
%left EQ NEQ GEQ LEQ G S
%left '+' '-'
%left '*' '/'
%left '^'
%left '('
%%

program : DEC declarations_global functions mainblock {printf("program corect sintactic\n");}	
		;

// Declaratii
declarations_global : declare ';' declarations_global
					| FS {scope++;}
					| MAIN {scope = 0;}
					;

declr : declare
	  | custom_type
		 ;

declare   : type_ ID 
				{
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					insertVar($2,$1);
					vars[noVars-1].isConst = x;
				}
		  | type_ ID ASSIGN NR 
		  		{
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					union value id1,id2;
					strcpy(id1.strVal, $2);
					insertVar($2,$1);
					if(strcmp($1,"float")  == 0 || strcmp($1,"const float") == 0) {
						id2.floatVal = $4;
						assign(2,id1,id2);
					}
					else{
						id2.intVal = $4; 
						assign(1,id1,id2);
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
	  				insertVar($2,$1);
					assign(2,id1,id2);
					vars[noVars-1].isConst = x;
	  			}
	   	  | type_ ID ASSIGN CH 
	   		    {
	   				int x;
	  				if(strncmp($1,"const",5) == 0) x = 1;
	 				else x = 0;
	   				union value id1,id2;
	  				strcpy(id1.strVal, $2);
	   				insertVar($2,$1);
	   				id2.charVal = $4;
	   				assign(3,id1,id2);
	   				vars[noVars-1].isConst = x;
	   	  	  	}
		  | type_ ID ASSIGN STR 
		 	    {
					int x;
					if(strncmp($1,"const",5) == 0) x = 1;
					else x = 0;
					union value id1,id2;
					strcpy(id1.strVal, $2);
					insertVar($2,$1);
					strcpy(id2.strVal, $4);
					assign(4,id1,id2);
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
					insertVar($2,$1);
					assign(5,id1,id2);
					vars[noVars-1].isConst = x;
  	 	   }
		  | type_ ID '[' NR ']' 
		  		{
					insertarray($1,$2,$4);
		  	  	}
		  ;

type_ : TYPE { $$ = $1;}
	  | CONST TYPE {strcat($1," "); strcat($1,$2); $$ = $1;}
	;

custom_type : CUSTOMTYPE ID '{' declare '}'
			| CONST CUSTOMTYPE ID '{' declare '}'

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
		  | PRT '('  STR ',' exp ')' {printf("%s%d\n",$3,evalAST($5));}
		  | returns
		  ;
asigments : ID ASSIGN ID 
		  | ID ASSIGN NR 
		  | ID ASSIGN statement 
		  | ID ASSIGN exp
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
			   | exp
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
	printSymbolTabel();
} 

int insertVar(char *name, char *type) {
     int i = 0;
	 char msg[100];
     for(i = 0; i < noVars; i++) {
          if(strcmp(vars[i].name, name) == 0 && (vars[i].scope == 1 || vars[i].scope == scope))
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
	arr[noArr].isConst = 0;
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

void assign(int type, union value id1, union value id2)
{
	union value x;  
	char msg[100];
	int j,i = existsVar(id1.strVal);
	if(i == -1)
	{
		sprintf(msg,"Variable %s doesn't exist",id1.strVal);
		yyerror(msg);
		return;
	}
	if(vars[i].isConst == 1)
	{
		sprintf(msg,"Variable %s is constant",vars[i].name);
		yyerror(msg);
		return;
	}
	vars[i].hasVal = 1;
	switch(type)
	{
		case 1:
			vars[i].val.intVal = id2.intVal;
		break;
		case 2:
			vars[i].val.floatVal = id2.floatVal;
		break;
		case 3:
			if(strcmp(vars[i].type,"char") != 0){
				sprintf(msg,"Can't assign a char value to variable %s of type %s",vars[i].name,vars[i].type);
				yyerror(msg);
				return;
			}
			vars[i].val.charVal = id2.charVal;
		break;
		case 4:
			if(strcmp(vars[i].type,"string") != 0){
				sprintf(msg,"Can't assign a string to variable %s of type %s",vars[i].name,vars[i].type);
				yyerror(msg);
				return;
			}
			vars[i].val.charVal = id2.strVal;
		break;
		case 5:
			j = existsVar(id2.strVal);
			if(i == -1){
				sprintf(msg,"Variable %s doesn't exist",id2.strVal);
				yyerror(msg);
				return;
			}
			if(strcmp(vars[i].type,vars[j].type) != 0){
				sprintf(msg,"Variable %s has not same type with variable %s",vars[i].type,vars[j].type);
				yyerror(msg);
			}
			else	vars[i].val  = vars[j].val;
		break;
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
			else if(strcmp(vars[i].type,"char") == 0)
				fprintf(file,"Type: [%s]      Name: [%s],   Const: [%s].    Value: [%c]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.charVal,scopes);
			else if(strcmp(vars[i].type,"float") == 0)
				fprintf(file,"Type: [%s]    Name: [%s]   Const: [%s]   Value: [%f]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.floatVal,scopes);
			else if(strcmp(vars[i].type,"string") == 0)
				fprintf(file,"Type: [%s]    Name: [%s]   Const: [%s]   Value: [%s]    Scope: [%s]\n",vars[i].type,vars[i].name,constant,vars[i].val.strVal,scopes);
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
