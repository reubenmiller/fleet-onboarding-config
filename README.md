## Onboarding

```sh
wget -O - https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/bootstrap.sh | sh -s -- --help
```

**Configure dev profile**

```sh
wget -O - https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/bootstrap.sh | sh -s -- --type c8y --env dev --profile main
```

Or configure a secondary profile

```sh
wget -O - https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/bootstrap.sh | sh -s -- --type c8y --env dev --profile monitoring
```

**Configure staging profile**

```sh
wget -O - https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/bootstrap.sh | sh -s -- --type c8y --env staging --profile monitoring
```
