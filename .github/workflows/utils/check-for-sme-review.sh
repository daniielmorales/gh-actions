PR_NUMBER=${1}
if [[ -z $PR_NUMBER ]]; then
  echo "Error: No pull request number specified."
  exit 1
fi

SME_REVIEWER=${2}
if [[ -z $SME_REVIEWER ]]; then
  echo "Error: No SME specified."
  exit 1
fi

# IF SME created no need to check approves
HAD_SME_CREATED=$(                  
  gh pr view $PR_NUMBER --json author |
    jq '.[] |
      .login as $author |
      '"${SME_REVIEWER}"' |
      index([$author]) != null'
)

if [ $HAD_SME_CREATED = true ]; then
  echo "SME ask for a double check"
  exit 0
fi

# ELSE we may need to double check all the approves
PR_SUBMITED_REVIEW=$(
  gh pr view $PR_NUMBER --json reviews
)
if [[ -z $PR_SUBMITED_REVIEW ]]; then
  echo 'Error: "gh api" returned no submited reviews.'
  exit 1
fi

REVIEWERS_WHO_ALREADY_APPROVED=$( 
  echo "${PR_SUBMITED_REVIEW}" |
  jq '. |
    .reviews | map(select(
      (.state | test("^approved$"; "i"))
    )) |
    map(.author.login)'
)

HAD_SME_APPROVED=$(
  echo "${SME_REVIEWER}" |
    jq '. |
      map(select( . as $in | '"$REVIEWERS_WHO_ALREADY_APPROVED"' | any(. == $in) )) | 
      length > 0'
)

if [ $HAD_SME_APPROVED = true ]; then
  echo "Has SME approve"
  exit 0
else
  echo "Missing SME approve"
  exit 1
fi
