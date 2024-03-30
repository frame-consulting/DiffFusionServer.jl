
const _COPY_OP = "COPY"
const _BUILD_OP = "BUILD"
const _BUILD_ASYNC_OP = "BUILD_ASYNC"
const _OPERATIONS = (_COPY_OP, _BUILD_OP, _BUILD_ASYNC_OP)

const _INFO_END_POINT = "/info"
const _ALIASES_END_POINT = "/aliases"
const _OPS_END_POINT = "/ops"
const _BULK_OPS_END_POINT = "/bulk"

const _DEFAULT_PROTOCOL = "http"
const _DEFAULT_SERVER = string(Sockets.localhost)
const _DEFAULT_PORT = 2024

const _DEFAULT_API_PATH = "/api"
const _DEFAULT_API_VERSION = "/v1"

const _DEFAULT_SERVER_ADRESS = _DEFAULT_PROTOCOL * "://" *_DEFAULT_SERVER * ":" * string(_DEFAULT_PORT)
const _DEFAULT_SERVER_URL = _DEFAULT_SERVER_ADRESS * _DEFAULT_API_PATH * _DEFAULT_API_VERSION
