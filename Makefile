TEMURIN_TAG := 11.0.14.1_1-jre
JOB := core-${TEMURIN_TAG}
CHECK_JOB := check-${TEMURIN_TAG}
CLEAN_JOB := clean-${TEMURIN_TAG}

all: ${CHECK_JOB} ${JOB}
check: ${CHECK_JOB}
clean: ${CLEAN_JOB}
.PHONY: all check clean ${JOB} ${CHECK_JOB} ${CLEAN_JOB}

${JOB}: core-%: Dockerfile
	docker build \
	  --build-arg TEMURIN_TAG=$* \
	  --tag dwolla/jenkins-agent-dotnet:$*-SNAPSHOT \
	  .

${CHECK_JOB}: check-%:
	grep --silent "^  temurin_tag: $*$$" .github/workflows/ci.yml

${CLEAN_JOB}: clean-%:
	docker image rm --force dwolla/jenkins-agent-dotnet:$*-SNAPSHOT