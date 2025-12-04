#!/bin/sh
set -e

COUNTRY=${COUNTRY:-}
ENV=${ENV:-dev}
TYPE=${TYPE:-c8y}
PROFILE_NAME="main"
DEVICE_ID="${DEVICE_ID:-}"
FORCE=${FORCE:-0}
export TEDGE_CONFIG_DIR="${TEDGE_CONFIG_DIR:-/etc/tedge}"
DEVICE_ONE_TIME_PASSWORD=${DEVICE_ONE_TIME_PASSWORD:-}

usage() {
    cat <<EOT
$0 [--env <dev|staging>] [--profile <main|name>] [--type <c8y|az|aws>] [--device-id <name>]

Bootstrap a thin-edge.io device using mapper configuration hosted in GitHub

FLAGS

  --env <dev|staging>       Environment to be configured, e.g. dev, staging
  --profile <main|other>    Cloud profile name. "main" refers to the primary/default typed connection
  --type <c8y|aws|az>       Cloud profile type
  --device-id <name>        Device id. If leave blank then the tedge-identity will be used, or the hostname
  --one-time-password <code>    Optional one-time-password used for registration with Cumulocity. Defaults to a random password

EOT
}

# argument parsing
while [ $# -gt 0 ]; do
    case "$1" in
        --device-id)
            DEVICE_ID="$2"
            shift
            ;;
        --one-time-password)
            DEVICE_ONE_TIME_PASSWORD="$2"
            shift
            ;;
        --country)
            COUNTRY="$2"
            ;;
        --type)
            TYPE="$2"
            shift
            ;;
        --env)
            ENV="$2"
            shift
            ;;
        --profile)
            PROFILE_NAME="$2"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
    esac
    shift
done

if [ -z "$COUNTRY" ]; then
    COUNTRY=$(curl -sf http://ipinfo.io/country)
fi

if [ -z "${DEVICE_ID:-}" ]; then
    DEVICE_ID=$(tedge config get device.id 2>/dev/null || tedge-identity 2>/dev/null || hostname)
fi

get_random_code() {
    awk '
function rand_string(n,         s,i) {
    for ( i=1; i<=n; i++ ) {
        s = s chars[int(1+rand()*numChars)]
    }
    return s
}
BEGIN{
    srand()
    for (i=48; i<=122; i++) {
        char = sprintf("%c", i)
        if ( char ~ /[[:alnum:]]/ ) {
            chars[++numChars] = char
        }
    }

    for (i=1; i<=1; i++) {print rand_string(30)}
}'
}

is_enrolled() {
    return 1
    # tedge cert show "$TYPE" >/dev/null 2>&1;
}

register() {
    if [ "$FORCE" != 1 ] && is_enrolled; then
        echo "The device has already been onboarded" >&2
        exit 1
    fi

    EXTRA_ARGS=
    if [ "$PROFILE_NAME" = "main" ]; then
        EXTRA_ARGS="--profile $PROFILE_NAME"
        CONFIG_FILE="/etc/tedge/mappers/${TYPE}.toml"
    else
        CONFIG_FILE="/etc/tedge/mappers/${TYPE}.d/${PROFILE_NAME}.toml"
    fi

    if [ -n "$C8Y_URL" ]; then
        # normalize the values
        C8Y_URL=$(echo "$C8Y_URL" | sed 's|https?://||g')
        tedge config set c8y.url "$C8Y_URL"
    fi

    if [ -z "$DEVICE_ONE_TIME_PASSWORD" ]; then
        # User didn't provide a value, so generate a randomized code
        DEVICE_ONE_TIME_PASSWORD=$(get_random_code)
    fi

    C8Y_URL=$(grep '^url =' "$CONFIG_FILE" | cut -d= -f2 | xargs)
    if [ -n "$C8Y_URL" ]; then
        echo "Register in Cumulocity using:" >&2
        echo "" >&2
        echo "  https://$C8Y_URL/apps/devicemanagement/index.html#/deviceregistration?externalId=$DEVICE_ID&one-time-password=$DEVICE_ONE_TIME_PASSWORD" >&2
        echo "" >&2
    fi

    tedge cert download "$TYPE" --device-id "$DEVICE_ID" --one-time-password "$DEVICE_ONE_TIME_PASSWORD" --retry-every 5s $EXTRA_ARGS
    tedge reconnect "$TYPE" $EXTRA_ARGS
    printf '\n\nDevice was enrolled successfully\n' >&2
}

configure_main() {
    mkdir -p "/etc/tedge/mappers"
    curl -sSLf "https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/${COUNTRY}/${ENV}/${TYPE}/main.toml" > "/etc/tedge/mappers/${TYPE}.toml"
}

configure_named_profile() {
    NAME="$1"
    mkdir -p "/etc/tedge/mappers/${TYPE}.d/"
    curl -sSLf "https://raw.githubusercontent.com/reubenmiller/fleet-onboarding-config/refs/heads/main/${COUNTRY}/${ENV}/${TYPE}/${NAME}.toml" > "/etc/tedge/mappers/${TYPE}.d/${NAME}.toml"
}

configure_mapper() {
    NAME="$1"
    case "$NAME" in
        main)
            configure_main "$NAME"
            ;;
        *)
            configure_named_profile "$NAME"
            ;;
    esac

    register
}

configure_mapper "$PROFILE_NAME"
