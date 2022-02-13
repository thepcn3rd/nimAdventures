git checkout --orphan temp
git add *
git commit -am "Initial Commit"
git branch -D main
git branch -m main
git push -f origin main
