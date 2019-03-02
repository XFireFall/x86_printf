tasm  /l main.asm
tasm  /l          lib.asm
tlink /t main.obj lib.obj, a
