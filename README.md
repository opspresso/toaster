# toast.sh

[![build](https://img.shields.io/github/actions/workflow/status/opspresso/toast.sh/push.yml?branch=main&style=for-the-badge&logo=github)](https://github.com/opspresso/toast.sh/actions/workflows/push.yml)
[![release](https://img.shields.io/github/v/release/opspresso/toast.sh?style=for-the-badge&logo=github)](https://github.com/opspresso/toast.sh/releases)

toast.sh는 AWS, Kubernetes, Git 등의 CLI 도구들을 더 쉽게 사용할 수 있도록 도와주는 쉘 스크립트 도구입니다.

## 주요 기능

* AWS 관련 기능
  - AWS 프로파일 관리 (`toast env`)
  - AWS 리전 변경 (`toast region`)
  - IAM 역할 전환 (`toast assume`)
  - AWS Vault 지원 (`toast av`)

* Kubernetes 관련 기능
  - 컨텍스트 전환 (`toast ctx`)
  - 네임스페이스 전환 (`toast ns`)

* Git 관련 기능
  - 저장소 클론 (`toast git clone`)
  - 브랜치 관리 (`toast git branch`)
  - 태그 관리 (`toast git tag`)
  - 원격 저장소 관리 (`toast git remote`)

* 기타 기능
  - SSH 접속 관리 (`toast ssh`)
  - MTU 설정 (`toast mtu`)
  - 스트레스 테스트 (`toast stress`)

## 설치 방법

```bash
bash -c "$(curl -fsSL toast.sh/install)"
```

## 사용 방법

```
================================================================================
 _                  _         _
| |_ ___   __ _ ___| |_   ___| |__
| __/ _ \ / _' / __| __| / __| '_ \\
| || (_) | (_| \__ \ |_ _\__ \ | | |
 \__\___/ \__,_|___/\__(-)___/_| |_|
================================================================================
Usage: toast {am|cdw|env|git|ssh|region|ssh|ctx|ns|update}
================================================================================
```

## 단축 명령어

```bash
alias t='toast'
alias tu='bash -c "$(curl -fsSL toast.sh/install)"'
alias tt='bash -c "$(curl -fsSL nalbam.github.io/dotfiles/run.sh)"'

# 디렉토리 이동
c() {
  local dir="$(toast cdw $@)"
  if [ -n "$dir" ]; then
    echo "$dir"
    cd "$dir"
  fi
}

# AWS Vault 실행
v() {
  local profile="$(toast av $@)"
  if [ -n "$profile" ]; then
    export AWS_VAULT= && aws-vault exec $profile --
  fi
}

# 자주 사용하는 명령어 별칭
alias i='toast am'      # AWS IAM 정보 확인
alias e='toast env'     # AWS 프로파일 설정
alias n='toast git'     # Git 명령어
alias s='toast ssh'     # SSH 접속
alias r='toast region'  # AWS 리전 변경
alias x='toast ctx'     # Kubernetes 컨텍스트 변경
alias z='toast ns'      # Kubernetes 네임스페이스 변경
```

## 라이선스

이 프로젝트는 [GNU General Public License v3.0](LICENSE)에 따라 라이선스가 부여됩니다.

## 기여하기

버그 리포트, 기능 요청, 풀 리퀘스트는 GitHub 저장소를 통해 환영합니다.
