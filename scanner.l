%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define MAX_LINE_LENG 256
#define MAX_ID_LEN 64
#define MAX_SYMBOLS 1000
#define HASH_SIZE 211

#define LIST strcat(buf, yytext)
#define token(t) {LIST; printf("<%s>\n", t);}
#define tokenInteger(t, s) {LIST; printf("<%s: %s>\n", t, s);}
#define tokenString(t, s) {LIST; printf("<%s: %s>\n", t, s);}
// add '' to op and delim
#define tokenOp(d) {LIST; printf("<'%s'>\n", d);}
#define tokenDelim(d) {LIST; printf("<'%s'>\n", d);}

// Symbol Table
char* symbolTable[HASH_SIZE];
int linenum = 1;
char buf[MAX_LINE_LENG];

// Hash function
unsigned int hash(char *s) {
    unsigned int h = 0;
    for (; *s; s++) h = (h << 4) + *s;
    return h % HASH_SIZE;
}

void create() {
    for (int i = 0; i < HASH_SIZE; i++) symbolTable[i] = NULL;
}

int lookup(char *s) {
    unsigned int i = hash(s);
    int start = i;
    while (symbolTable[i] != NULL) {
        if (strcmp(symbolTable[i], s) == 0) return i;
        i = (i + 1) % HASH_SIZE;
        if (i == start) break;
    }
    return -1;
}

int insert(char *s) {
    unsigned int i = hash(s);
    int start = i;
    while (symbolTable[i] != NULL) {
        if (strcmp(symbolTable[i], s) == 0) return i;
        i = (i + 1) % HASH_SIZE;
        if (i == start) break;
    }
    symbolTable[i] = strdup(s);
    return i;
}

void dump() {
    printf("Symbol Table:\n");
    for (int i = 0; i < HASH_SIZE; i++) {
        if (symbolTable[i] != NULL)
            printf("%s\n", symbolTable[i]);
    }
}
%}

%option noyywrap
%x COMMENT

KEYWORD bool|break|case|char|const|continue|default|do|double|else|extern|false|float|for|foreach|if|int|print|println|read|return|string|switch|true|void|while
ID [a-zA-Z_][a-zA-Z0-9_]*
INT [0-9]+
REAL [-+]?([0-9]+\.[0-9]*([eE][-+]?[0-9]+)?|[0-9]+[eE][-+]?[0-9]+)
STRING \"([^\"\n]|\"\")*?\"
OP \+\+|\+|--|-|\*|\/|%|==|!=|<=|>=|=|<|>|\|\||&&|!
DELIM [\(\)\[\]\{\},.:;]

%%
"//".*"\n" {    // single line comment
    printf("%d: %s", linenum, yytext);
    linenum++;
    buf[0] = '\0';
}

"/*" {      // multi line comment
    BEGIN(COMMENT);
    LIST;
}
<COMMENT>{
    "*/" {
        LIST;
        BEGIN(INITIAL);
    }
    \n {
        LIST;
        printf("%d: %s\n", linenum, buf);
        linenum++;
        buf[0] = '\0';
    }
    . {
        LIST;
    }
}


{REAL}               {tokenString("real", yytext);}
{INT}                {tokenInteger("integer", yytext);}
{STRING}             {
                        char str[MAX_LINE_LENG] = "";
                        for (int i = 1; i < yyleng - 1; ++i) {
                            if (yytext[i] == '"' && yytext[i+1] == '"') {
                                strcat(str, "\"");
                                i++;
                            } else {
                                int len = strlen(str);
                                str[len] = yytext[i];
                                str[len + 1] = '\0';
                            }
                        }
                        tokenString("string", str);
                    }

{KEYWORD}            {
                        char upper[MAX_ID_LEN];
                        for (int i = 0; i < yyleng; i++) {
                            upper[i] = toupper(yytext[i]);  // turn into uppercase
                        }
                        upper[yyleng] = '\0';
                        token(upper);
                    }
{ID}                 {
                        if (lookup(yytext) == -1) insert(yytext);
                        tokenString("ID", yytext);
                    }
{OP}                 {tokenOp(yytext);}
{DELIM}              {tokenDelim(yytext);}
[ \t\r]+             {LIST;}
\n                   {
                        LIST;
                        printf("%d: %s\n", linenum, buf);
                        linenum++;
                        buf[0] = '\0';
                    }
.                    {
                        LIST;
                        printf("%d: %s\n", linenum, buf);
                        fprintf(stderr, "bad character: '%s'\n", yytext);
                        exit(1);
                    }
%%

int main(int argc, char **argv) {
    create();
    buf[0] = '\0';
    yylex();
    if (buf[0] != '\0') {
        printf("%d: %s\n", linenum, buf);
    }
    dump();
    return 0;
}