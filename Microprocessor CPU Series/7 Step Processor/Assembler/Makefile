asmbl.exe: asmbl.l asmbl.y
	bison -d asmbl.y
	flex asmbl.l
	gcc -g -o asmbl lex.yy.c asmbl.tab.c -LH:\MinGW\msys\1.0\lib -lfl
