all:
	antlr3 Lex.g
	antlr3 Syn.g
	javac TokenConv.java
	java TokenConv Syn.tokens Irt.java 
	antlr3 *.java
	antlr3 camle -cg testsk.le
	cat testsk.ass
	./assmule testsk.ass

clean:
	rm -f *.class
	rm -f *.tokens
	rm -f *.ass
	rm -f Lex.java
	rm -f Syn.java

local:
	./antLEr3 Lex.g
	./antLEr3 Syn.g
	javac TokenConv.java
	java TokenConv Syn.tokens Irt.java
	./antLEr3 *.java
	./antLEr3 camle -cg testsk.le
#	cat testsk.ass
#	./assmule testsk.ass
