# Assuming
# env:
#   PR_NUMBER: ${{ github.event.number }}
PR_NUMBER=42
# GITHUB_REPOSITORY is built-in
GITHUB_REPOSITORY=platformsh-templates/fastapi

# rm -rf template-builder
cd template-builder
git checkout master 
git branch -D sync-fastapi-42
cd ..

# SETUP
TRACKED_FILES=( .platform.app.yaml .platform/services.yaml .platform/applications.yaml )
MODIFIED_FILES=()
OPEN_TB_PR=0

# DETECT CHANGES
for FILE in "${TRACKED_FILES[@]}"
do
    if test -f "$FILE"; then
        CHANGE=$(git diff --exit-code $FILE)
        if [ "$CHANGE" == "" ];then
            echo "$FILE is unchanged"
        else 
            echo "$FILE has been modified"
            OPEN_TB_PR=1
            MODIFIED_FILES+=($FILE)
        fi 
    else
        echo "File $FILE not found"
    fi
done

# APPLY CHANGES
if [ "$OPEN_TB_PR" -eq 1 ]; then
    echo "Revisions detected to tracked files";

    # Get current template name.
    arrIN=(${GITHUB_REPOSITORY//\// })
    TEMPLATE=${arrIN[1]}   
    SYNC_BRANCH=sync-$TEMPLATE-$PR_NUMBER

    # Clone template-builder, and create a new branch that matches changes in template repo.
    # git clone git@github.com:platformsh/template-builder.git
    cd template-builder
    pwd
    git checkout -b $SYNC_BRANCH
    for FILE in "${MODIFIED_FILES[@]}"
    do
        echo "Updating $FILE"
        cp ../$FILE templates/$TEMPLATE/files 
    done
    # git add 
    cd .. templates/$TEMPLATE/files 
    pwd
    STAGE=$(IFS=" " ; echo "${MODIFIED_FILES[*]}")
    git add $STAGE 
    cd ../../..

    git commit -m "Match changes to $STAGE"
    git push origin $SYNC_BRANCH

    gh pr create \
        --head $SYNC_BRANCH \
        --title "Sync: matching $GITHUB_REPOSITORY#$PR_NUMBER" \
        --body "Syncing updates made in to https://github.com/platformsh-templates/$TEMPLATE/pull/$PR_NUMBER"
else
    echo "No revisisions detected. All is well.";
fi




