# Project1-Scanner

## Hint

Must execute in Linux environment.
With gcc and flex

## Executing step

1. Generate C source code

    $flex scanner.l

2. Compile executable file with gcc

    $gcc lex.yy.c -o scanner -lfl

3. Execute scanner with sD file input (shown as HelloWorld.sd)

    $./scanner < HelloWorld.sd