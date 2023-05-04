GITHUB_REPOSITORY=${1}

if [[ -z $GITHUB_REPOSITORY ]]; then
  echo "Error: No GitHub repository identifier specified."
  exit 1
fi

PR_NUMBER=${2}

if [[ -z $PR_NUMBER ]]; then
  echo "Error: No pull request number specified."
  exit 1
fi

SME_REVIEWER=${3}

if [[ -z $SME_REVIEWER ]]; then
  echo "Error: No SME specified."
  exit 1
fi

PR_REVIEW_REQUESTS=$(
  gh pr view $PR_NUMBER --json reviewRequests reviews author
)

if [[ -z $PR_REVIEW_REQUESTS ]]; then
  echo 'Error: "gh api" returned no review requests.'
  exit 1
fi

PR_SUBMITED_REVIEW=$(
  gh pr view $PR_NUMBER --json reviews
)

if [[ -z $PR_SUBMITED_REVIEW ]]; then
  echo 'Error: "gh api" returned no submited reviews.'
  exit 1
fi

HAD_SME_CREATED=$(
  gh pr view $PR_NUMBER --json author |
  jq '.[] |
  select(.login=="'"${SME_REVIEWER}"'") != null'
)

HAD_SME_APPROVED=$(
  echo "${REVIEWERS_WHO_ALREADY_APPROVED}" |
    jq '. |
      index(["'"${SME_REVIEWER}"'"]) != null'
  )

if [[ $HAD_SME_CREATED == "true" ]]; then
  echo "SME ask for a double check"
  exit 0
elif [[ $HAD_SME_APPROVED == "true" ]]; then
  echo "Has SME approve"
  exit 0
else
  echo "Missing SME approve"
  exit 1
fi