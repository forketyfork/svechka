svechka: svechka.o
	ld -macosx_version_min 11.0.0 -o svechka svechka.o -lSystem -syslibroot `xcrun -sdk macosx --show-sdk-path` -e _start -arch arm64 

svechka.o: svechka.s
	as -o svechka.o svechka.s

build-default-metal:
	xcrun -sdk macosx metal -frecord-sources=flat add.metal

build-test-app:
	gcc -framework Metal -framework Cocoa -x objective-c -o Test ./test.m

