# Deploy Checklist

## What This Repo Now Covers

- Runtime config diagnostics and safer bootstrap
- Proxy auth token support and real SSE streaming
- Firestore rules/indexes versioned in repo
- Android release signing scaffold with `keystore.properties`
- Mobile permissions and AdMob placeholders
- Auth completeness: password reset and email verification actions
- CI baseline and deploy docs

## Still Needed From Console/Credentials

- Final Android package name / iOS bundle ID
- Firebase Auth provider configuration
- Google Sign-In OAuth client setup and Android SHA keys
- Apple Sign In capability and App Store signing assets
- AdMob app IDs and unit IDs
- Store product IDs for IAP
- Proxy hosting URL, HTTPS, domain and secret rotation

## Local Steps

```bash
cp .env.example .env
flutter pub get
flutter analyze
flutter test
```

## Proxy Local Steps

```bash
cd proxy-server
cp .env.example .env
source .env
node server.mjs
```

## Release Smoke Test

1. Email login works
2. Password reset email arrives
3. Verification email sends correctly
4. Google/Apple login works on real devices
5. Proxy `/health`, `/v1/models`, `/v1/chat`, streaming all work
6. Banner and rewarded ads load with real IDs
7. Purchase and restore flows work on sandbox stores
8. Cloud backup push/pull works with Firestore rules enabled
