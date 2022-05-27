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
더버하바기비	{return(ADD); }
빼배기비	{return(SUB); }
고봅하바기비	{return(MUL); }
나바누붓세벰	{return(DIV); }
나바머버지비	{return(MOD); }
제베고봅그븐	{return(SQRT);}

크브다바	{return(GT); }
크브거버나바가밭다바 {return (GE);}
자박다바	{return(LT); }
자박거버나바가밭다바 {return (LE);}
가밭다바	{return (EQ);}

마반야뱍에베	{return (IF);}
마반야뱍에베또보느븐 {return (IF_ELSE_ST);} 
아반니비라바며변 {return (ELSE);}
바반보복	{return (WHILE);}

이빕려벽	{ return (INPUT);}
:=		{return(ASSGN); }
;		{return(STMTEND); }
시비자박		{return(START); }
끄븥		{return(END); }
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
