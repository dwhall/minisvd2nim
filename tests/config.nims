switch("path", "$projectDir/../src")
switch("hint", "XDeclaredButNotUsed:off")

patchFile("stdlib", "volatile", "volatile_mock")
