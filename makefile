SRC    = scanner.l
LEXARG = flex
GCCARG = gcc lex.yy.c -o
OUTPUT = scanner

all: scanner.l
	${LEXARG} ${SRC}
	${GCCARG} ${OUTPUT}

run: scanner.l
	${LEXARG} ${SRC}
	${GCCARG} ${OUTPUT}
	./scanner

clean:
	rm scanner
	rm lex.yy.c
