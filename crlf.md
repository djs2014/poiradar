Source:
https://stackoverflow.com/questions/48692741/how-can-i-make-all-line-endings-eols-in-all-files-in-visual-studio-code-unix

Searched for a simple solution for days and didn't have any success until I found some Git commands that changed all files from CRLF to LF.

As pointed out by Mats, make sure to commit changes before executing the following commands.

In the root folder type the following.

```
git config core.autocrlf false

git rm --cached -r .         # Don’t forget the dot at the end

git reset --hard
```