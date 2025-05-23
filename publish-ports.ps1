vcpkg --x-builtin-ports-root=./ports --x-builtin-registry-versions-dir=./versions format-manifest --all
vcpkg --x-builtin-ports-root=./ports --x-builtin-registry-versions-dir=./versions x-add-version --all --verbose
git add ports/**
git add versions/**
git commit -m "ports: updated"
git push
