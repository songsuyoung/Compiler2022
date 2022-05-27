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
int IfCnt=-1;
int setCnt=-1;
int desCnt=-1;
//if문을 관리할 cnt
int Cnt=-1;
int IfElseCnt=-1;
int ElseCnt=-1;
//if/else를 관리할 cnt

int WhileCnt=-1;
int LoopCnt=-1;
int OutCnt=-1;
//반복문 관리할 cnt 
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
//void genIfLabel();
//void genElseLabel();
//void genEndLabel();
void	dwgen();
int	gentemp();
/*내가 생성한 함수*/
Node * MakeITRTree(int,Node *,Node *,Node *);
Node * MakeSTMTree(int, Node *, Node *,Node *);
void	processStatement(Node *); //조건문 반복문 수행 함수
void	processOperator(int,Node *); //연산문 수행함수.
void 	processCondition(int,Node *); //연산자 수행함수
/*내가 생성한 함수, 최대한 노드를 이용해보자.*/

//void	assgnstmt(int, int);
//void	numassgn(int, int);
//void	addstmt(int, int, int);
//void	substmt(int, int, int);
int	insertsym(char *);

%}

%token ASSGN ID NUM STMTEND START WHILE END ID2 IF IF_ELSE_ST ELSE GT GE LT LE EQ THEN INPUT CHAROUT SQRT
/*add,sub는 같은 우선순위*//*div,mul는 같은 우선순위(왼쪽부터 차례로 우선순위 적용)*/
/*CONEND는 만약에 (조건문) 면 (stmt)적용*/
%left ADD SUB 
%left MUL MOD DIV

%%

program	: START stmt_list END	{ if (errorcnt==0) { codegen($2); dwgen();} } //codegen은 node를 출력
;	

stmt_list: stmt_list stmt {$$=MakeListTree($1,$2);}
	|  stmt		{$$=MakeListTree(NULL,$1);}
	| error STMTEND	{ errorcnt++; yyerrok;}
	;

stmt	:   unmatched {$$=$1;}
	|   iteration {$$=$1;}
	|   assign    {$$=$1;}
	;

assign  : ID ASSGN expr STMTEND {$1->token=ID2; $$=MakeOPTree(ASSGN,$1,$3);}	;

iteration : WHILE condition_stmt stmt stmt {$$=MakeSTMTree(WHILE,$2,$3,$4);}
	;

unmatched : IF condition_stmt stmt {$$=MakeOPTree(IF,$2,$3);}
	| IF_ELSE_ST condition_stmt stmt ELSE stmt { $$=MakeSTMTree(IF_ELSE_ST,$2,$3,$5); }
;

condition_stmt	: 	fact GT fact { $$=MakeOPTree(GT,$1,$3); }
|	fact GE fact {$$=MakeOPTree(GE,$1,$3); }
|	fact LT fact {$$=MakeOPTree(LT,$1,$3); }
|	fact LE fact {$$=MakeOPTree(LE,$1,$3); }
;

expr	: expr ADD term	{ $$=MakeOPTree(ADD,$1,$3); }
	|	expr SUB term	{ $$=MakeOPTree(SUB, $1, $3); }
	|	term
	;

term	:	term MUL fact	{ $$=MakeOPTree(MUL, $1, $3); }
	|	term DIV fact   { $$=MakeOPTree(DIV, $1, $3); }
	|	term MOD fact	{ $$=MakeOPTree(MOD, $1, $3); }
	|	term SQRT fact	{ $$=MakeOPTree(MUL,$1,$1); }
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
	if(op==IF){
		//setCnt++;
		IfCnt++;
	}
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
	
	if(op==WHILE){
		WhileCnt++;
	}
	if(op==IF){
		setCnt++;
		Cnt++;
	}
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
			fprintf(fp,"-\n");
			
			IfElseCnt++;
			if(WhileCnt>-1&&WhileCnt!=OutCnt&&LoopCnt>-1){
				fprintf(fp,"COPY\n");
				fprintf(fp,"GOMINUS LOOPOUT%d\n",++OutCnt);
				fprintf(fp,"GOFALSE LOOPOUT%d\n",OutCnt);
				//set 고칠예정.
			}
			if(IfElseCnt>-1&&Cnt==IfElseCnt){
				fprintf(fp,"GOFALSE ELSE%d\n",IfElseCnt);//0
			}
			//fprintf(fp,"GOFALSE ELSE%d\n",ElseCnt);
			IfElseCnt++;
			IfCnt++;
			
			if(IfCnt>-1&&Cnt!=IfCnt&&Cnt>-1)
				fprintf(fp,"GOFALSE OUT%d\n",++setCnt);
			break;
		case LT: //작다 오른쪽이 왼쪽보다 작다 -> 1
			fprintf(fp,"-\n");
			IfElseCnt++;
			if(WhileCnt>-1&&WhileCnt!=OutCnt&&LoopCnt>-1){
				fprintf(fp,"GOMINUS LOOPOUT%d\n",++OutCnt);
				//set 고칠예정.
			}
			if(IfElseCnt>-1&&Cnt==IfElseCnt){
				fprintf(fp,"GOFALSE ELSE%d\n",IfElseCnt);//0
			}
			//fprintf(fp,"GOFALSE ELSE%d\n",ElseCnt);
			IfElseCnt++;
			IfCnt++;
			
			if(IfCnt>-1&&Cnt!=IfCnt&&Cnt>-1)
				fprintf(fp,"GOFALSE OUT%d\n",++setCnt);
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

void processStatement(Node *ptr){

	switch(ptr->token){
		case IF:
		case IF_ELSE_ST:
			fprintf(fp,"LABEL OUT%d\n",++desCnt);
			break;
		case WHILE:
			fprintf(fp,"GOTO LOOP%d\n",WhileCnt);
			fprintf(fp,"LABEL LOOPOUT%d\n",OutCnt);
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
			processStatement(ptr);
			break;	
		case ASSGN:
			fprintf(fp,":=\n");

			if(WhileCnt>-1&&LoopCnt!=WhileCnt){
				fprintf(fp,"LABEL LOOP%d\n",++LoopCnt);
			}
			if(IfElseCnt>-1&&IfCnt>-1&&Cnt>-1){
				fprintf(fp,"GOTO OUT%d\n",setCnt);
				IfCnt=-1;
			}
			
			if(IfElseCnt>-1&&ElseCnt!=IfElseCnt&&ElseCnt!=Cnt)
				fprintf(fp,"LABEL ELSE%d\n",++ElseCnt);
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

