%{
#include <string.h>
#include "cbu2.h"
#define MAXSYM	100
#define	MAXSYMLEN	20
char symtbl[MAXSYM][MAXSYMLEN];
int lineno=1;
int insertsym();
int maxsym=0;
char s[30];
int temp;

%}
sp		[ \t]
ws		{sp}+
nl		\n
eletter	[A-Za-z]
hletter	[\xb0-\xfe][\xa0-\xfe]
letter	({eletter}|{hletter})
digit	[0-9]
number 	[0-9]+\.[0-9]+
id		{letter}({letter}|{digit})*
%%
{ws}	{/* do nothing */}
{nl}	{lineno++; }
�����Ϲٱ��	{return(ADD); }
������	{return(SUB); }
�����Ϲٱ��	{return(MUL); }
���ٴ��׼���	{return(DIV); }
���ٸӹ�����	{return(MOD); }

ũ��ٹ�	{return(GT); }
ũ��Ź����ٰ���ٹ� {return (GE);}
�ڹڴٹ�	{return(LT); }
�ڹڰŹ����ٰ���ٹ� {return (LE);}
����ٹ�	{return (EQ);}

���ݾ߹󿡺�	{return (IF);}
���ݾ߹󿡺��Ǻ����� {return (IF_ELSE_ST);} 
�ƹݴϺ��ٸ纯 {return (ELSE);}
�纯		{return (THEN);}
�ٹݺ���	{return (WHILE);}
�̺�����	{ return (INPUT);}
:=		{return(ASSGN); }
;		{return(STMTEND); }
�ú��ڹ�		{return(START); }
����		{return(END); }
{id}	{strcpy(s, yytext); temp=insertsym(s); yylval=MakeNode(ID,temp); return(ID);}
{digit}+		{sscanf(yytext, "%d", &temp); yylval=MakeNode(NUM,temp); return(NUM);}
.		{printf("invalid token %s\n", yytext); }
%%

int insertsym(s)
char *s;
{
int i;

	for(i=0;i<maxsym; i++) {
		if(strcmp(s, symtbl[i])==0) return(i);
		}
	if (i<MAXSYM-1) {
		strcpy(symtbl[maxsym],s);
		maxsym++;
		return(maxsym-1);
		}
	else
		{printf("symbol table overflow\n");}
	return(0);
}

yywrap() {}