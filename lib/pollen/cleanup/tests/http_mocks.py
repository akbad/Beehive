"""HTTP mock helpers for cleanup handler tests."""
import json
from dataclasses import dataclass
from typing import Any, Mapping, Tuple, Union


# ━━━━━━━━━━━━ types/type aliases used for mock HTTP endpoints ━━━━━━━━━━━━

# type used to explicitly specify byte literals corresponding to malformed/non-JSON responses
@dataclass(frozen=True)
class NonJsonHttpResponse:
    raw_bytes: bytes

# type alias for JSON bodies
JsonBody = dict[str, Any]

# type alias for (HTTP method, endpoint path) given in HTTP requests
ReqMethodAndPath = Tuple[str, str]

# type alias for possible HTTP response formats used in testing
# including Exception allows testing HTTP/network failures 
#   (via subclasses like URLError, HTTPError,...)
RespSpec = Union[JsonBody, Exception, NonJsonHttpResponse]

# type alias for map from (HTTP method, endpoint path) to HTTP response
RouteMap = Mapping[ReqMethodAndPath, RespSpec]


# ━━━━━━━━━━━━ reusable mock HTTP endpoint creation functionality ━━━━━━━━━━━━

def create_mock_http_endpoint(responses_map: RouteMap):
    """Factory for creating mock HTTP endpoint responses.
    
    Returns:
        A mock function suitable for use with patch("...urlopen", side_effect=...)
    """
    from unittest.mock import MagicMock

    def mock_http_endpoint(req, timeout=None):
        url = req.full_url if hasattr(req, "full_url") else str(req)
        method = req.get_method() if hasattr(req, "get_method") else "GET"

        # iterate while checking if u is a substring of the url portion (instead of performing
        #   direct lookup) since requests specify full url, but responses_map only contains the
        #   path portion; acceptable since responses_map will usually contain < 10 items
        for (m, u), response in responses_map.items():
            if m == method and u in url:
                if isinstance(response, Exception):
                    raise response
                mock_resp = MagicMock()

                if isinstance(response, NonJsonHttpResponse):
                    # NonJsonHttpResponse already contains raw bytes, so simply return those
                    mock_resp.read.return_value = response.raw_bytes
                else:
                    # serialize stored response then convert to bytes to replicate HTTP response format
                    mock_resp.read.return_value = json.dumps(response).encode()

                # for `with mock_resp as ...` statement:
                # __enter__ return value is what gets passed into the obj after `as`
                mock_resp.__enter__ = MagicMock(return_value=mock_resp)
                mock_resp.__exit__ = MagicMock(return_value=False)
                return mock_resp

        # return empty response by default
        mock_resp = MagicMock()

        # create a bytes literal instead of a string to replicate HTTP response format
        mock_resp.read.return_value = b"{}"
        mock_resp.__enter__ = MagicMock(return_value=mock_resp)
        mock_resp.__exit__ = MagicMock(return_value=False)
        return mock_resp

    return mock_http_endpoint
