%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    KEYWORD,
    ID,
    OP,
    PUNC,
    INT,
    DOUBLE,
    CHAR,
    SCI,
    STRING
} Token;

char *tok_str[] = {
    "key",
    "id",
    "op",
    "punc",
    "integer",
    "double",
    "char",
    "sci",
    "string"
};

const int LEN = 1024;
int line_count = 0, source_on = 1, token_on = 1, pos = 0, err_pos;
char line[LEN];

void record(char *str) {
    strcpy(line+pos, str);
    pos += strlen(str);
}

void print(Token type, char *tok) {
    if (token_on) {
        if (type == STRING) {
            printf("#%s:", tok_str[type]);
            int i = 1;
            while (tok[i+1] != '\0') putchar(tok[i++]);
            putchar('\n');
        } else {
            printf("#%s:%s\n", tok_str[type], tok);
        }
    }
}

void print_line() {
    line_count++;
    line[pos] = '\0';
    pos = 0;
    if (source_on) {
        printf("%d:%s\n", line_count, line);
    }
}

void error() {
    err_pos = pos;
}

void print_error() {
    line_count++;
    line[pos] = '\0';
    pos = 0;
    fprintf(stderr, "Error at line %d:%s\n", line_count, line + err_pos);
}

%}

%x LINE_COMMENT
%x COMMENT
%x PRAGMA
%x ERROR
id_error_set ([^ #\n\t\*\/%\+\-<>=&\|!:;,\.\[\]\(\)\{\}])
sci_error_set ([^\n\t0-9])

%%

 /* Pragma directive */
# { record(yytext); BEGIN PRAGMA; }
<PRAGMA>pragma[ ]source[ ]on { record(yytext); source_on = 1; }
<PRAGMA>pragma[ ]source[ ]off { record(yytext); source_on = 0; }
<PRAGMA>pragma[ ]token[ ]on { record(yytext); token_on = 1; }
<PRAGMA>pragma[ ]token[ ]off { record(yytext); token_on = 0; }
<PRAGMA>\n { print_line(); BEGIN 0; }

 /* Comment */
\/\* { record(yytext); BEGIN COMMENT; }
<COMMENT>\n { print_line(); }
<COMMENT>. { record(yytext); }
<COMMENT>\*\/ { record(yytext); BEGIN 0; }
\/\/ { record(yytext); BEGIN LINE_COMMENT; }
<LINE_COMMENT>. { record(yytext); }
<LINE_COMMENT>\n { print_line(); BEGIN 0; }

 /* Keywords */
void|int|double|bool|char|null { record(yytext); print(KEYWORD, yytext); }
for|while|do|if|else|switch|return|break|continue { record(yytext); print(KEYWORD, yytext); }
const|true|false|struct|case|default { record(yytext); print(KEYWORD, yytext); }
fclose|clearerr|feof|ferror|fflush|fgetpos|fopen|fread|freopen|fseek|fsetpos|ftell { record(yytext); print(KEYWORD, yytext); }
fwrite|remove|rename|rewind|setbuf|setvbuf|tmpfile|tmpnam|fprintf|printf|sprintf { record(yytext); print(KEYWORD, yytext); }
vfprintf|vprintf|vsprintf|fscanf|scanf|sscanf|fgetc|fgets|fputc|fputs { record(yytext); print(KEYWORD, yytext); }
getc|getchar|gets|putc|putchar|puts|ungetc|perror { record(yytext); print(KEYWORD, yytext); }

 /* scientific notation */
[0-9]+(e|E)((\+|-)?)[0-9]+ { record(yytext); print(SCI, yytext); }
[0-9]*\.[0-9]+(e|E)((\+|-)?)[0-9]+ { record(yytext); print(SCI, yytext); }
[0-9]+\.[0-9]*(e|E)((\+|-)?)[0-9]+ { record(yytext); print(SCI, yytext); }

 /* Integer and double */
[1-9][0-9]* { record(yytext); print(INT, yytext); }
0 { record(yytext); print(INT, yytext); }
[0-9]*\.[0-9]+ { record(yytext); print(DOUBLE, yytext); }
[0-9]+\.[0-9]* { record(yytext); print(DOUBLE, yytext); }

 /* ID, operator and punctuation */
[_[:alpha:]][_[:alnum:]]* { record(yytext); print(ID, yytext); }
\+|-|\*|\/|%|\+\+|--|<|<=|>|>=|==|!=|=|&&|\|\||!|\*|& { record(yytext); print(OP, yytext); }
:|;|,|\.|\[|\]|\(|\)|\{|\} { record(yytext); print(PUNC, yytext); }

 /* String and char */
\"[^\"\n]*\" { record(yytext); print(STRING, yytext); }
\'(.|\\n|\\t)?\' { record(yytext); print(CHAR, yytext); }

 /* Other rules */
\n { print_line(); }
[ ]+ { record(yytext); }

 /* Error handling */
[0-9]+\.[0-9]*\.[0-9]+ { error(); record(yytext); BEGIN ERROR; }
[0-9]*\.[0-9]+\.[0-9]* { error(); record(yytext); BEGIN ERROR; }
0([0-9]+) { error(); record(yytext); BEGIN ERROR; }
({id_error_set}+)([a-zA-Z_]+)(({id_error_set}+)?) { error(); record(yytext); BEGIN ERROR; }
[0-9]+(e|E)((\+|-)?)({sci_error_set}+) { error(); record(yytext); BEGIN ERROR; }
[0-9]*\.[0-9]+(e|E)((\+|-)?)({sci_error_set}+) { error(); record(yytext); BEGIN ERROR; }
[0-9]+\.[0-9]*(e|E)((\+|-)?)({sci_error_set}+) { error(); record(yytext); BEGIN ERROR; }


. { error(); record(yytext); BEGIN ERROR; }
<PRAGMA>. { error(); err_pos--; record(yytext); BEGIN ERROR; }

<ERROR>\n { print_error(); exit(1); BEGIN 0; }
<ERROR>. { record(yytext); }

%%

int main() {
    yylex();
    return 0;
}

int yywrap() {
    return 1;
}
