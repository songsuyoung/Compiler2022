%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DEBUG	0

#define	 MAXSYM	100
#define	 MAXSYMLEN	20
#define	 MAXTSYMLEN	15
#define	 MAXTSYMBOL	MAXSYM/2

#define STMTLIST 500

typedef struct nodeType {
	int token;
	int tokenval;
	struct nodeType *son;
	struct nodeType *brother;
} Node;

#define YYSTYPE Node*
int IfCnt=0;
int ElseCnt=0;
int IfElseCnt=0;
int tsymbolcnt=0;
int errorcnt=0;

FILE *yyin;
FILE *fp;

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node * MakeOPTree(int, Node*, Node*);
Node * MakeNode(int, int);
Node * MakeListTree(Node*, Node*);
void codegen(Node* );
void prtcode(int,Node*);
void Input(char *);
void genIfLabel();
void genElseLabel();
void genEndLabel();
void	dwgen();
int	gentemp();
/*내가 생성한 함수*/
Node * MakeSTMTree(int, Node *, Node *,Node *);
void	processStatement(int,Node *); //조건문 반복문 수행 함수
void	processOperator(int,Node *); //연산문 수행함수.
void 	processCondition(int,Node *); //연산자 수행함수
/*내가 생성한 함수, 최대한 노드를 이용해보자.*/

//void	assgnstmt(int, int);
//void	numassgn(int, int);
//void	addstmt(int, int, int);
//void	substmt(int, int, int);
int	insertsym(char *);

%}

%token ASSGN ID NUM STMTEND START WHILE END ID2 IF IF_ELSE_ST ELSE GT GE LT LE EQ THEN INPUT CHAROUT 
/*add,sub는 같은 우선순위*//*div,mul는 같은 우선순위(왼쪽부터 차례로 우선순위 적용)*/
/*CONEND는 만약에 (조건문) 면 (stmt)적용*/
%left ADD SUB 
%left MUL MOD DIV

%%

program	: START stmt_list END	{ if (errorcnt==0) { codegen($2); dwgen();} } //codegen은 node를 출력
	;

stmt_list: Statement {$$=$1;}
	;

Statement : ExpressionStatement 	{$$=MakeListTree(NULL, $1);}
	| ExpressionStatement SelectionStatement {$$=MakeListTree($1,$2);}
	| error STMTEND	{ errorcnt++; yyerrok;}
	;
			
SelectionStatement:  unmatched {$$=$1;} ;	

unmatched : IF condition_stmt stmt_list {$$=MakeOPTree(IF,$1,$2);}
	| IF_ELSE_ST condition_stmt stmt_list ELSE stmt_list { $$=MakeSTMTree(IF_ELSE_ST,$2,$3,$5); }
	 ;

ExpressionStatement: stmt ExpressionStatement {$$=MakeListTree($1, $2);} 
	| stmt {$$=MakeListTree(NULL,$1);}
	;
stmt: ID ASSGN expr STMTEND	{$1->token=ID2; $$=MakeOPTree(ASSGN,$1,$3);} 
	;

condition_stmt	: 	expr GT expr { $$=MakeOPTree(GT,$1,$3); }
|	expr GE expr {$$=MakeOPTree(GE,$1,$3); }
|	expr LT expr {$$=MakeOPTree(LT,$1,$3); }
|	expr LE expr {$$=MakeOPTree(LE,$1,$3); }
;

expr	: expr ADD term	{ $$=MakeOPTree(ADD,$1,$3); }
	|	expr SUB term	{ $$=MakeOPTree(SUB, $1, $3); }
	|	term
	;

term	:	term MUL fact	{ $$=MakeOPTree(MUL, $1, $3); }
	|	term DIV fact   { $$=MakeOPTree(DIV, $1, $3); }
	|	term MOD fact	{ $$=MakeOPTree(MOD, $1, $3); }
	|	fact
	;

fact	:	ID		{ /* ID node is created in lex */ }
	|	NUM		{ /* NUM node is created in lex */ }
	;

%%
int main(int argc, char *argv[]) 
{
	printf("\nSong Su Young Goblin language CBU compiler v2.0\n");
	printf("(C) Copyright by Jae Sung Lee (jasonlee@cbnu.ac.kr), 2022.\n");

	if (argc == 2)
		yyin = fopen(argv[1], "r");
	else {
		printf("Usage: cbu2 inputfile\noutput file is 'a.asm'\n");
		return(0);
	}

	fp=fopen("a.asm", "w");

	yyparse();


	fclose(yyin);
	fclose(fp);

	if (errorcnt==0) 
	{ printf("Successfully compiled. Assembly code is in 'a.asm'.\n");}
}

yyerror(s)
	char *s;
{
	printf("%s (line %d)\n", s, lineno);
}

Node * MakeOPTree(int op, Node* operand1, Node* operand2)
{
	Node * newnode;

	newnode = (Node *)malloc(sizeof (Node));
	newnode->token = op;
	newnode->tokenval = op;
	newnode->son = operand1;
	newnode->brother = NULL;
	operand1->brother = operand2;
	return newnode;
}


Node * MakeSTMTree(int op, Node *operand1, Node *stmt,Node *stmt1){
	
	Node * newnode;

	newnode = (Node *)malloc(sizeof(Node));
	newnode->token=op;
	newnode->tokenval=op;
	newnode->son=operand1;
	newnode->brother=NULL;
	operand1->brother=stmt;
	stmt->brother=stmt1;
	
	return newnode;
}

Node * MakeNode(int token, int operand)
{
	Node * newnode;
	newnode = (Node *) malloc(sizeof (Node));
	newnode->token = token;
	newnode->tokenval = operand; 
	newnode->son = newnode->brother = NULL;
	return newnode;
}

//void genEndLabel(){
//	fprintf(fp,"LABEL END\n",ConCnt);
//	ConCnt--;
//}
void genIfLabel(){
	fprintf(fp,"LABEL IF%d\n",IfCnt++);
}

void genElseLabel(){
	fprintf(fp,"LABEL ELSE%d\n",ElseCnt++);
}
Node * MakeListTree(Node* operand1, Node* operand2)
{
	Node * newnode;
	Node * node;

	if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
	}
	else {
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
	}
}

void processOperator(int token,Node *ptr){

	switch(token){
		case ADD:
			fprintf(fp,"+\n");
			break;
		case SUB:
			fprintf(fp,"-\n");
			break;
		case DIV:
			fprintf(fp,"/\n");
			break;
		case MUL:
			fprintf(fp,"*\n");
			break;
		case MOD:
			fprintf(fp,"POP\n"); //B 빼기
			fprintf(fp,"POP\n"); //B 빼기
			if(ptr->son->token==NUM&&ptr->son->brother->token==NUM){ //가능
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval);
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval);
				fprintf(fp,"PUSH %d\n",ptr->son->brother->tokenval);
				fprintf(fp,"/\n"); //나누기연산
				fprintf(fp,"PUSH %d\n",ptr->son->brother->tokenval);
			}else if(ptr->son->token==NUM&&ptr->son->brother->token!=NUM){ //가능
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval);
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval);
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->brother->tokenval]);
				fprintf(fp,"/\n");
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->brother->tokenval]);
			}else if(ptr->son->token!=NUM&&ptr->son->brother->token==NUM){
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->tokenval]);
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->tokenval]);
				fprintf(fp,"PUSH %d\n",ptr->son->brother->tokenval);
				fprintf(fp,"/\n");
				fprintf(fp,"PUSH %d\n",ptr->son->brother->tokenval);
			}else{
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->tokenval]);
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->tokenval]);
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->brother->tokenval]);
				fprintf(fp,"/\n");
				fprintf(fp,"RVALUE %s\n",symtbl[ptr->son->brother->tokenval]);
			}
				fprintf(fp,"*\n");
				fprintf(fp,"-\n");
			break;
	}

}


void codegen(Node * root)
{
	DFSTree(root);

}

void DFSTree(Node * n)
{
	if (n==NULL) {
		return;
	}
	DFSTree(n->son);
	prtcode(n->token,n);
	DFSTree(n->brother);

}
void processCondition(int token,Node *ptr){

	
	switch(token){ //오른쪽이 왼쪽보다 크다. 0일때 Out
		case GT: //크다 음수일경우 0을 삽입
			fprintf(fp,"POP\n");
			fprintf(fp,"POP\n");
			if(ptr->son->token==NUM&&ptr->son->brother->token==NUM){ //가능
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval>ptr->son->brother->tokenval);
			}
			else if(ptr->son->token!=NUM&&ptr->son->brother->token==NUM) //가능
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval] > ptr->son->brother->tokenval);
			else if(ptr->son->token==NUM&&ptr->son->brother->token!=NUM) //가능
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval>symtbl[ptr->son->brother->tokenval]);
			else
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]>symtbl[ptr->son->brother->tokenval]);
			IfCnt++;
			fprintf(fp,"GOFALSE ELSE%d\n",ElseCnt);
			break;
		case LT: //작다 오른쪽이 왼쪽보다 작다 -> 1

			if(ptr->son->token==NUM&&ptr->son->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval<ptr->son->brother->tokenval);
			else if(ptr->son->token!=NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]<ptr->brother->tokenval);
			else if(ptr->son->token==NUM&&ptr->brother->token!=NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval<symtbl[ptr->brother->tokenval]);
			else
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]<symtbl[ptr->brother->tokenval]);
			break;
		case GE: //크거나 같다.

			if(ptr->son->token==NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval>=ptr->brother->tokenval);
			else if(ptr->son->token!=NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]>=ptr->brother->tokenval);
			else if(ptr->son->token==NUM&&ptr->brother->token!=NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval>=symtbl[ptr->brother->tokenval]);
			else
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]>=symtbl[ptr->brother->tokenval]);
			break; 
		case LE: //작거나 같다
			
			if(ptr->son->token==NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval<=ptr->brother->tokenval);
			else if(ptr->son->token!=NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]<=ptr->brother->tokenval);
			else if(ptr->son->token==NUM&&ptr->brother->token!=NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval<=symtbl[ptr->brother->tokenval]);
			else
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]<=symtbl[ptr->brother->tokenval]);
			break;
		case EQ:

			if(ptr->son->token==NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval==ptr->brother->tokenval);
			else if(ptr->son->token!=NUM&&ptr->brother->token==NUM)
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]==ptr->brother->tokenval);
			else if(ptr->son->token==NUM&&ptr->brother->token!=NUM)
				fprintf(fp,"PUSH %d\n",ptr->son->tokenval==symtbl[ptr->brother->tokenval]);
			else
				fprintf(fp,"PUSH %d\n",symtbl[ptr->son->tokenval]==symtbl[ptr->brother->tokenval]);
			break;
	}

}

void processStatement(int token,Node *ptr){

	switch(token){
		case IF: case IF_ELSE_ST:
			IfCnt++;
			fprintf(fp,"LABEL OUT\n");
			break;
		case WHILE:
			fprintf(fp,"LABEL LOOP\n");
			processCondition(ptr->son->brother->token,ptr->son->brother);
			
			processOperator(ptr->son->brother->brother->token,ptr->son->brother->brother);
//fprintf(fp,"GOFALSE OUT\n");
			//fprintf(fp,"GOTO LOOP\n");
			break;
	}
}
void prtcode(int token,Node *ptr)
{
	switch (token) {
		case ID:
			fprintf(fp,"RVALUE %s\n", symtbl[ptr->tokenval]);
			break;
		case ID2:
			fprintf(fp, "LVALUE %s\n", symtbl[ptr->tokenval]);
			break;
		case NUM:
			fprintf(fp, "PUSH %d\n", ptr->tokenval);
			break;
		case ADD:
		case SUB:
		case MUL:
		case DIV:
		case MOD:
			processOperator(token,ptr);
			break;
		case GT: case LT: case LE: case GE: case EQ:
			processCondition(token,ptr);
			break;
		case IF:case IF_ELSE_ST:case WHILE:
			processStatement(token,ptr);
			break;	
		case ASSGN:
			fprintf(fp, ":=\n");
			if(IfCnt-1==ElseCnt){
				fprintf(fp,"GOTO OUT\n");
				genElseLabel();
			}
			break;
		case STMTLIST:
		default:
			break;
	}
}

int gentemp()
{
	char buffer[MAXTSYMLEN];
	char tempsym[MAXSYMLEN]="TTCBU";

	tsymbolcnt++;
	if (tsymbolcnt > MAXTSYMBOL) printf("temp symbol overflow\n");
	_itoa(tsymbolcnt, buffer, 10); //숫자를 문자로 변환하는 함수, 즉 입력을 생성은 여기서 하네....
	strcat(tempsym, buffer);
	return( insertsym(tempsym) ); // Warning: duplicated symbol is not checked for lazy implementation
}

void dwgen()
{
	int i;
	fprintf(fp, "HALT\n");
	fprintf(fp, "$ -- END OF EXECUTION CODE AND START OF VAR DEFINITIONS --\n");

	// Warning: this code should be different if variable declaration is supported in the language 
	for(i=0; i<maxsym; i++) 
		fprintf(fp, "DW %s\n", symtbl[i]);
	fprintf(fp, "END\n");
}

