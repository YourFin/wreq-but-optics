{- |
Module      : Network.Wreq.ButOptics
Description : wreq, but Optics!

This module provides re-exports the same api as `Network.Wreq`,
adapted to the @optics@ library instead of lens.

The documentation for `Network.Wreq` is great,
and you should be able to refer to it ~verbatim.

Differences:

@
\-\- Load this library instead of the standard
\-\- one, so we get better type errors
import "Network.Wreq.Optics"

\-\- Import Optics!
import "Optics"

\-\- Many of the examples in `Network.Wreq` use
\-\- Lens operators like ^. ; `Optics` doesn't
\-\- export these by default. Let's import them:
import "Optics.Operators"
@
-}
module Network.Wreq.ButOptics (
    -- * HTTP verbs

    -- ** Sessions

    -- ** GET
    get,
    getWith,

    -- ** POST
    post,
    postWith,

    -- ** HEAD
    head_,
    headWith,

    -- ** OPTIONS
    options,
    optionsWith,

    -- ** PUT
    put,
    putWith,

    -- ** PATCH
    patch,
    patchWith,

    -- ** DELETE
    delete,
    deleteWith,

    -- ** Custom Method
    customMethod,
    customMethodWith,
    customHistoriedMethod,
    customHistoriedMethodWith,

    -- ** Custom Payload Method
    customPayloadMethod,
    customPayloadMethodWith,
    customHistoriedPayloadMethod,
    customHistoriedPayloadMethodWith,

    -- * Incremental consumption of responses

    -- ** GET
    foldGet,
    foldGetWith,

    -- * Configuration
    Options,
    defaults,
    Optics.manager,
    Optics.header,
    Optics.param,
    Optics.redirects,
    Optics.headers,
    Optics.params,
    Optics.cookie,
    Optics.cookies,
    Optics.checkResponse,

    -- ** Authentication
    Auth,
    AWSAuthVersion (..),
    Optics.auth,
    basicAuth,
    oauth1Auth,
    oauth2Bearer,
    oauth2Token,
    awsAuth,
    awsFullAuth,
    awsSessionTokenAuth,

    -- ** Proxy settings
    Proxy (Proxy),
    Optics.proxy,
    httpProxy,

    -- ** Using a manager with defaults
    withManager,

    -- * Payloads for POST and PUT
    Payload (..),

    -- ** URL-encoded form data
    FormParam (..),
    FormValue,

    -- ** Multipart form data
    Part,
    Optics.partName,
    Optics.partFileName,
    Optics.partContentType,
    Optics.partGetBody,

    -- *** Smart constructors
    partBS,
    partLBS,
    partText,
    partString,
    partFile,
    partFileSource,

    -- * Responses
    Response,
    Optics.responseBody,
    Optics.responseHeader,
    Optics.responseLink,
    Optics.responseCookie,
    Optics.responseHeaders,
    Optics.responseCookieJar,
    Optics.responseStatus,
    Optics.Status,
    Optics.statusCode,
    Optics.statusMessage,
    HistoriedResponse,
    Optics.hrFinalRequest,
    Optics.hrFinalResponse,
    Optics.hrRedirects,

    -- ** Link headers
    Optics.Link,
    Optics.linkURL,
    Optics.linkParams,

    -- ** Decoding responses
    JSONError (..),
    asJSON,
    asValue,

    -- * Cookies
    Optics.Cookie,
    Optics.cookieName,
    Optics.cookieValue,
    Optics.cookieExpiryTime,
    Optics.cookieDomain,
    Optics.cookiePath,

    -- * Parsing responses
    Optics.atto,
    Optics.atto_,
) where

import Network.Wreq hiding (
    -- \* Configuration

    -- \** Proxy setup

    -- \* Cookie
    Cookie,
    -- \* Response

    -- \* HistoriedResponse
    HistoriedResponse,
    -- \** Status

    -- \* Link header
    Link,
    Options,
    -- \* POST body part
    Part,
    Response,
    Status,
    -- \* Parsing
    atto,
    atto_,
    auth,
    checkResponse,
    cookie,
    cookieDomain,
    cookieExpiryTime,
    cookieName,
    cookiePath,
    cookieValue,
    cookies,
    header,
    headers,
    hrFinalRequest,
    hrFinalResponse,
    hrRedirects,
    linkParams,
    linkURL,
    manager,
    param,
    params,
    partContentType,
    partFileName,
    partGetBody,
    partName,
    proxy,
    redirects,
    responseBody,
    responseCookie,
    responseCookieJar,
    responseHeader,
    responseHeaders,
    responseLink,
    responseStatus,
    statusCode,
    statusMessage,
 )
import Network.Wreq.Optics as Optics
