# OAuth

## Google

### Step 1: Create a new project

### Step 2: Get a domain

- [ ] Domain Name 정하기

#### Option 1: GCP

1. Go to [Cloud DNS API](https://console.cloud.google.com/marketplace/product/google/dns.googleapis.com?returnUrl=/net-services/dns/zones?referrer%3Dsearch%26inv%3D1%26invt%3DAblT1w%26project%3Dgen-lang-client-0591884777&inv=1&invt=AblT1w&project=gen-lang-client-0591884777)

#### Option 2: AWS

1. Go to [Route 53](https://console.aws.amazon.com/route53/home?region=us-east-1#hosted-zones:)

### Step 3: Create a privacy policy and terms of service

- App Domains
  - [ ] 홈페이지 URL
  - [ ] 개인정보보호 정책 URL
  - [ ] 이용약관 URL

### Step 999: Enable the Google+ API

1. Go to [Google API Console](https://console.developers.google.com/) and enable the OAuth API for your project.

  - API 및 서비스 |> OAuth 동의 화면 |> 동의 

2. Obtain OAuth _client_ credentials.

  - Google 인증 플랫폼 |> 개요 |> OAUTH 클라이언트 만들기 |> 동의화면 구성

  - **Requirements:**
    - App Domains
      - [ ] 홈페이지 URL
      - [ ] 개인정보보호 정책 URL
      - [ ] 이용약관 URL
    - App Logo
      - [ ] 로고만들기
