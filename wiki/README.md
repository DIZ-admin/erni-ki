# ERNI-KI GitHub Wiki (offline draft)

This folder contains ready-to-publish wiki pages. If the GitHub Wiki is
disabled, enable it in repository settings or push these files to the wiki
repository:

```bash
git clone https://github.com/DIZ-admin/erni-ki.wiki.git
cd erni-ki.wiki
cp -r ../erni-ki/wiki/* .
git status
git add .
git commit -m "Add initial ERNI-KI wiki"
git push origin main
```

If the wiki repository does not exist yet, enabling the Wiki in GitHub will
create it automatically. After pushing, the Wiki tab will display these pages.
