## Onboarding

```sh
COUNTRY=$(curl -sf http://ipinfo.io/country)
ENV=staging
TYPE=c8y
PROFILE_NAME="monitoring"
mkdir -p "/etc/tedge/mappers/${TYPE}.d/"
curl -sSLf "https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/${COUNTRY}/${ENV}/${TYPE}/${PROFILE_NAME}.toml" > "/etc/tedge/mappers/${TYPE}.d/${PROFILE_NAME}.toml"
tedge connect "$TYPE" --profile "$PROFILE_NAME"
```