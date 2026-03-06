{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

{- |
Module      : Network.Wreq.Optics.Adaptions
Description : Optics replacements for wreq's lens API

This module directly adapts the @lens@ code in "Network.Wreq.Lens"
to @optics@. Documentation is copied ~verbatim.

When reading the examples in this module, you should assume the
following environment:

@
\-\- Make it easy to write literal 'Text' values.
\{\-\# LANGUAGE OverloadedStrings \#\-\}

\-\- The Core wreq library
import "Network.Wreq.ButOptics"

\-\- Optics!
import "Optics"
@
-}
module Network.Wreq.Optics (
    -- * Configuration
    Options,
    manager,
    proxy,
    auth,
    header,
    param,
    redirects,
    headers,
    params,
    cookie,
    cookies,
    ResponseChecker,
    checkResponse,

    -- ** Proxy setup
    Proxy,
    proxyHost,
    proxyPort,

    -- * Cookie
    Cookie,
    cookieName,
    cookieValue,
    cookieExpiryTime,
    cookieDomain,
    cookiePath,
    cookieCreationTime,
    cookieLastAccessTime,
    cookiePersistent,
    cookieHostOnly,
    cookieSecureOnly,
    cookieHttpOnly,

    -- * Response
    Response,
    responseBody,
    responseHeader,
    responseLink,
    responseCookie,
    responseHeaders,
    responseCookieJar,
    responseStatus,
    responseVersion,

    -- * HistoriedResponse
    HistoriedResponse,
    hrFinalResponse,
    hrFinalRequest,
    hrRedirects,

    -- ** Status
    Status,
    statusCode,
    statusMessage,

    -- * Link header
    Link,
    linkURL,
    linkParams,

    -- * POST body part
    Part,
    partName,
    partFileName,
    partContentType,
    partGetBody,

    -- * Parsing
    atto,
    atto_,
) where

import Control.Applicative (many)
import Data.Attoparsec.ByteString (Parser, endOfInput, parseOnly)
import Data.Attoparsec.ByteString.Char8 (char, char8, peekChar, peekChar', sepBy1, skipSpace)
import qualified Data.Attoparsec.ByteString.Char8 as A8
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B8
import qualified Data.ByteString.Lazy as L
import Data.Text (Text)
import Data.Time.Clock (UTCTime)
import Network.HTTP.Client (
    Cookie,
    CookieJar,
    HistoriedResponse,
    Manager,
    ManagerSettings,
    Proxy,
    Request,
    RequestBody,
    Response,
 )
import qualified Network.HTTP.Client as HTTP
import Network.HTTP.Client.MultipartFormData (Part)
import Network.HTTP.Types.Header (Header, HeaderName, ResponseHeaders)
import Network.HTTP.Types.Status (Status)
import Network.HTTP.Types.Version (HttpVersion)
import Network.Mime (MimeType)
import qualified Network.Wreq.Lens as WrqLens
import Network.Wreq.Types (Auth, Link (Link), Options, ResponseChecker)
import Optics.Core (
    Fold,
    Lens,
    Lens',
    Traversal',
    filtered,
    folding,
    lensVL,
    traversalVL,
    (%),
 )

-- * Configuration

{- | A lens onto configuration of the connection manager provided by
the http-client package.

In this example, we enable the use of TLS for (hopefully)
secure connections:

@
import "Network.HTTP.Client.TLS"

let opts = 'Network.Wreq.defaults' & 'set' 'manager' (Left 'Network.HTTP.Client.TLS.tlsManagerSettings')
'Network.Wreq.getWith' opts \"https:\/\/httpbin.org\/get\"
@

Lens version: 'Network.Wreq.Lens.manager'
-}
manager :: Lens' Options (Either ManagerSettings Manager)
manager = lensVL WrqLens.manager

{- | A lens onto proxy configuration.

Example:

@
let opts = 'Network.Wreq.defaults' & 'set' 'proxy' ('Just' ('Network.Wreq.httpProxy' \"localhost\" 8000))
'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/get\"
@

Lens version: 'Network.Wreq.Lens.proxy'
-}
proxy :: Lens' Options (Maybe Proxy)
proxy = lensVL WrqLens.proxy

{- | A lens onto request authentication.

Example (note the use of TLS):

@
let opts = 'Network.Wreq.defaults' & 'set' 'auth' ('Just' ('Network.Wreq.basicAuth' \"user\" \"pass\"))
'Network.Wreq.getWith' opts \"https:\/\/httpbin.org\/basic-auth\/user\/pass\"
@

Lens version: 'Network.Wreq.Lens.auth'
-}
auth :: Lens' Options (Maybe Auth)
auth = lensVL WrqLens.auth

{- | A lens onto all headers with the given name (there can
legitimately be zero or more).

Example:

@
let opts = 'Network.Wreq.defaults' & 'set' ('header' \"Accept\") [\"*\/*\"]
'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/get\"
@

Lens version: 'Network.Wreq.Lens.header'
-}
header :: HeaderName -> Lens' Options [ByteString]
header n = lensVL (WrqLens.header n)

{- | A lens onto all headers (there can legitimately be zero or more).

In this example, we print all the headers sent by default with
every request.

@
print ('view' 'headers' 'Network.Wreq.defaults')
@

Lens version: 'Network.Wreq.Lens.headers'
-}
headers :: Lens' Options [Header]
headers = lensVL WrqLens.headers

{- | A lens onto all query parameters with the given name (there can
legitimately be zero or more).

In this example, we construct the query URL
\"@http:\/\/httpbin.org\/get?foo=bar&foo=quux@\".

@
let opts = 'Network.Wreq.defaults' & 'set' ('param' \"foo\") [\"bar\", \"quux\"]
'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/get\"
@

Lens version: 'Network.Wreq.Lens.param'
-}
param :: Text -> Lens' Options [Text]
param n = lensVL (WrqLens.param n)

{- | A lens onto all query parameters.

Lens version: 'Network.Wreq.Lens.params'
-}
params :: Lens' Options [(Text, Text)]
params = lensVL WrqLens.params

{- | A lens onto the maximum number of redirects that will be followed
before an exception is thrown.

In this example, a 'Network.HTTP.Client.HttpException' will be
thrown with a 'Network.HTTP.Client.TooManyRedirects' constructor,
because the maximum number of redirects allowed will be exceeded.

@
let opts = 'Network.Wreq.defaults' & 'set' 'redirects' 3
'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/redirect\/5\"
@

Lens version: 'Network.Wreq.Lens.redirects'
-}
redirects :: Lens' Options Int
redirects = lensVL WrqLens.redirects

{- | A lens to get the optional status check function.

Lens version: 'Network.Wreq.Lens.checkResponse'
-}
checkResponse :: Lens' Options (Maybe ResponseChecker)
checkResponse = lensVL WrqLens.checkResponse

{- | A lens onto all cookies.

Lens version: 'Network.Wreq.Lens.cookies'
-}
cookies :: Lens' Options (Maybe CookieJar)
cookies = lensVL WrqLens.cookies

{- | A traversal onto the cookie with the given name, if one exists.

N.B. This is an \"illegal\" 'Traversal'': we can change the
'cookieName' of the associated 'Cookie' so that it differs from the
name provided to this function.

Lens version: 'Network.Wreq.Lens.cookie'
-}
cookie :: ByteString -> Traversal' Options Cookie
cookie n = traversalVL (WrqLens.cookie n)

-- ** Proxy setup

{- | A lens onto the hostname portion of a proxy configuration.

Lens version: 'Network.Wreq.Lens.proxyHost'
-}
proxyHost :: Lens' Proxy ByteString
proxyHost = lensVL WrqLens.proxyHost

{- | A lens onto the TCP port number of a proxy configuration.

Lens version: 'Network.Wreq.Lens.proxyPort'
-}
proxyPort :: Lens' Proxy Int
proxyPort = lensVL WrqLens.proxyPort

-- * Cookie

{- | A lens onto the name of a cookie.

Lens version: 'Network.Wreq.Lens.cookieName'
-}
cookieName :: Lens' Cookie ByteString
cookieName = lensVL WrqLens.cookieName

{- | A lens onto the value of a cookie.

Lens version: 'Network.Wreq.Lens.cookieValue'
-}
cookieValue :: Lens' Cookie ByteString
cookieValue = lensVL WrqLens.cookieValue

{- | A lens onto the expiry time of a cookie.

Lens version: 'Network.Wreq.Lens.cookieExpiryTime'
-}
cookieExpiryTime :: Lens' Cookie UTCTime
cookieExpiryTime = lensVL WrqLens.cookieExpiryTime

{- | A lens onto the domain of a cookie.

Lens version: 'Network.Wreq.Lens.cookieDomain'
-}
cookieDomain :: Lens' Cookie ByteString
cookieDomain = lensVL WrqLens.cookieDomain

{- | A lens onto the path of a cookie.

Lens version: 'Network.Wreq.Lens.cookiePath'
-}
cookiePath :: Lens' Cookie ByteString
cookiePath = lensVL WrqLens.cookiePath

{- | A lens onto the creation time of a cookie.

Lens version: 'Network.Wreq.Lens.cookieCreationTime'
-}
cookieCreationTime :: Lens' Cookie UTCTime
cookieCreationTime = lensVL WrqLens.cookieCreationTime

{- | A lens onto the last access time of a cookie.

Lens version: 'Network.Wreq.Lens.cookieLastAccessTime'
-}
cookieLastAccessTime :: Lens' Cookie UTCTime
cookieLastAccessTime = lensVL WrqLens.cookieLastAccessTime

{- | A lens onto whether a cookie is persistent across sessions (also
known as a \"tracking cookie\").

Lens version: 'Network.Wreq.Lens.cookiePersistent'
-}
cookiePersistent :: Lens' Cookie Bool
cookiePersistent = lensVL WrqLens.cookiePersistent

{- | A lens onto whether a cookie is host-only.

Lens version: 'Network.Wreq.Lens.cookieHostOnly'
-}
cookieHostOnly :: Lens' Cookie Bool
cookieHostOnly = lensVL WrqLens.cookieHostOnly

{- | A lens onto whether a cookie is secure-only, such that it will
only be used over TLS.

Lens version: 'Network.Wreq.Lens.cookieSecureOnly'
-}
cookieSecureOnly :: Lens' Cookie Bool
cookieSecureOnly = lensVL WrqLens.cookieSecureOnly

{- | A lens onto whether a cookie is \"HTTP-only\".

Such cookies should be used only by browsers when transmitting HTTP
requests.  They must be unavailable in non-browser environments,
such as when executing JavaScript scripts.

Lens version: 'Network.Wreq.Lens.cookieHttpOnly'
-}
cookieHttpOnly :: Lens' Cookie Bool
cookieHttpOnly = lensVL WrqLens.cookieHttpOnly

-- * Response

{- | A lens onto the status of an HTTP response.

Lens version: 'Network.Wreq.Lens.responseStatus'
-}
responseStatus :: Lens' (Response body) Status
responseStatus = lensVL WrqLens.responseStatus

{- | A lens onto the version of an HTTP response.

Lens version: 'Network.Wreq.Lens.responseVersion'
-}
responseVersion :: Lens' (Response body) HttpVersion
responseVersion = lensVL WrqLens.responseVersion

{- | A lens onto all headers in an HTTP response.

Lens version: 'Network.Wreq.Lens.responseHeaders'
-}
responseHeaders :: Lens' (Response body) ResponseHeaders
responseHeaders = lensVL WrqLens.responseHeaders

{- | A lens onto the body of a response.

@
r <- 'Network.Wreq.get' \"http:\/\/httpbin.org\/get\"
print ('view' 'responseBody' r)
@

Lens version: 'Network.Wreq.Lens.responseBody'
-}
responseBody :: Lens (Response body0) (Response body1) body0 body1
responseBody = lensVL WrqLens.responseBody

{- | A lens onto all cookies set in the response.

Lens version: 'Network.Wreq.Lens.responseCookieJar'
-}
responseCookieJar :: Lens' (Response body) CookieJar
responseCookieJar = lensVL WrqLens.responseCookieJar

{- | A traversal onto all matching named headers in an HTTP response.

To access the first matching header, use 'Optics.Core.preview':

@
r <- 'Network.Wreq.get' \"http:\/\/httpbin.org\/get\"
print ('preview' ('responseHeader' \"Content-Type\") r)
@

To access all (zero or more) matching headers, use 'Optics.Core.toListOf':

@
r <- 'Network.Wreq.get' \"http:\/\/httpbin.org\/get\"
print ('toListOf' ('responseHeader' \"Set-Cookie\") r)
@

Lens version: 'Network.Wreq.Lens.responseHeader'
-}
responseHeader ::
    -- | Header name to match.
    HeaderName ->
    Traversal' (Response body) ByteString
responseHeader n = traversalVL (WrqLens.responseHeader n)

{- | A fold over any cookies that match the given name.

@
r <- 'Network.Wreq.get' \"http:\/\/www.nytimes.com\/\"
print ('preview' ('responseCookie' \"RMID\") r)
@

Lens version: 'Network.Wreq.Lens.responseCookie'
-}
responseCookie ::
    -- | Name of cookie to match.
    ByteString ->
    Fold (Response body) Cookie
responseCookie name =
    lensVL WrqLens.responseCookieJar
        % folding HTTP.destroyCookieJar
        % filtered ((== name) . HTTP.cookie_name)

{- | A fold over @Link@ headers, matching on both parameter name
and value.

For example, here is a @Link@ header returned by the GitHub search API.

> Link:
>   <https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>; rel="next",
>   <https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34>; rel="last"

And here is an example of how we can retrieve the URL for the @next@ link
programatically.

@
r <- 'Network.Wreq.get' \"https:\/\/api.github.com\/search\/code?q=addClass+user:mozilla\"
print ('preview' ('responseLink' \"rel\" \"next\" '%' 'linkURL') r)
@

Lens version: 'Network.Wreq.Lens.responseLink'
-}
responseLink ::
    -- | Parameter name to match.
    ByteString ->
    -- | Parameter value to match.
    ByteString ->
    Fold (Response body) Link
responseLink name val =
    responseHeader "Link"
        % folding parseLinks
        % filtered (\(Link _ ps) -> (name, val) `elem` ps)

-- * HistoriedResponse

{- | A lens onto the final request of a historied response.

Lens version: 'Network.Wreq.Lens.hrFinalRequest'
-}
hrFinalRequest :: Lens' (HistoriedResponse body) Request
hrFinalRequest = lensVL WrqLens.hrFinalRequest

{- | A lens onto the final response of a historied response.

Lens version: 'Network.Wreq.Lens.hrFinalResponse'
-}
hrFinalResponse :: Lens' (HistoriedResponse body) (Response body)
hrFinalResponse = lensVL WrqLens.hrFinalResponse

{- | A lens onto the list of redirects of a historied response.

Lens version: 'Network.Wreq.Lens.hrRedirects'
-}
hrRedirects :: Lens' (HistoriedResponse body) [(Request, Response L.ByteString)]
hrRedirects = lensVL WrqLens.hrRedirects

-- ** Status

{- | A lens onto the numeric identifier of an HTTP status.

Lens version: 'Network.Wreq.Lens.statusCode'
-}
statusCode :: Lens' Status Int
statusCode = lensVL WrqLens.statusCode

{- | A lens onto the textual description of an HTTP status.

Lens version: 'Network.Wreq.Lens.statusMessage'
-}
statusMessage :: Lens' Status ByteString
statusMessage = lensVL WrqLens.statusMessage

-- * Link header

{- | A lens onto the URL portion of a @Link@ element.

Lens version: 'Network.Wreq.Lens.linkURL'
-}
linkURL :: Lens' Link ByteString
linkURL = lensVL WrqLens.linkURL

{- | A lens onto the parameters of a @Link@ element.

Lens version: 'Network.Wreq.Lens.linkParams'
-}
linkParams :: Lens' Link [(ByteString, ByteString)]
linkParams = lensVL WrqLens.linkParams

-- * POST body part

{- | A lens onto the name of the @\<input\>@ element associated with
part of a multipart form upload.

Lens version: 'Network.Wreq.Lens.partName'
-}
partName :: Lens' Part Text
partName = lensVL WrqLens.partName

{- | A lens onto the filename associated with part of a multipart form
upload.

Lens version: 'Network.Wreq.Lens.partFileName'
-}
partFileName :: Lens' Part (Maybe String)
partFileName = lensVL WrqLens.partFileName

{- | A lens onto the content-type associated with part of a multipart
form upload.

Lens version: 'Network.Wreq.Lens.partContentType'
-}
partContentType :: Traversal' Part (Maybe MimeType)
partContentType = traversalVL WrqLens.partContentType

{- | A lens onto the code that fetches the data associated with part
of a multipart form upload.

Lens version: 'Network.Wreq.Lens.partGetBody'
-}
partGetBody :: Lens' Part (IO RequestBody)
partGetBody = lensVL WrqLens.partGetBody

-- * Parsing

{- | Turn an attoparsec 'Parser' into a 'Fold'.

Both headers and bodies can contain complicated data that we may
need to parse.

Example: when responding to an OPTIONS request, a server may return
the list of verbs it supports in any order, up to and including
changing the order on every request (which httpbin.org /actually
does/!).  To deal with this possibility, we parse the list, then
sort it.

@
import Data.Attoparsec.ByteString.Char8 as A
import Data.List (sort)

let comma = skipSpace >> \",\" >> skipSpace
let verbs = A.takeWhile isAlpha_ascii \`sepBy\` comma

r <- 'Network.Wreq.options' \"http:\/\/httpbin.org\/get\"
'toListOf' ('responseHeader' \"Allow\" '%' 'atto' verbs '%' 'to' sort) r
@

Lens version: 'Network.Wreq.Lens.atto'
-}
atto :: Parser a -> Fold ByteString a
atto p = folding (parseOnly p)

{- | The same as 'atto', but ensures that the parser consumes the
entire input.

Equivalent to:

@
'atto_' myParser = 'atto' (myParser '<*' 'endOfInput')
@

Lens version: 'Network.Wreq.Lens.atto_'
-}
atto_ :: Parser a -> Fold ByteString a
atto_ p = atto (p <* endOfInput)

-- * Link header parser (vendored from wreq: Network.Wreq.Internal.Link)

parseLinks :: ByteString -> [Link]
parseLinks = links
  where
    links :: ByteString -> [Link]
    links hdr = case parseOnly f hdr of
        Left _ -> []
        Right xs -> xs
      where
        f = sepBy1 (link <* skipSpace) (char8 ',' *> skipSpace) <* endOfInput
    link :: Parser Link
    link = Link <$> url <*> many (char8 ';' *> skipSpace *> param')
      where
        url = char8 '<' *> A8.takeTill (== '>') <* char8 '>' <* skipSpace

    param' :: Parser (ByteString, ByteString)
    param' = do
        name <- paramName
        skipSpace *> "=" *> skipSpace
        c <- peekChar'
        let isTokenChar = A8.inClass "!#$%&'()*+./0-9:<=>?@a-zA-Z[]^_`{|}~-"
        val <- case c of
            '"' -> quotedString
            _ -> A8.takeWhile isTokenChar
        skipSpace
        return (name, val)

    quotedString :: Parser ByteString
    quotedString = char '"' *> (fixup <$> body) <* char '"'
      where
        body = A8.scan Literal $ \s c ->
            case (s, c) of
                (Literal, '\\') -> backslash
                (Literal, '"') -> Nothing
                _ -> literal
        literal = Just Literal
        backslash = Just Backslash
        fixup = B8.pack . go . B8.unpack
          where
            go ('\\' : x@'\\' : xs) = x : go xs
            go ('\\' : x@'"' : xs) = x : go xs
            go (x : xs) = x : go xs
            go xs = xs

    paramName :: Parser ByteString
    paramName = do
        name <- A8.takeWhile1 $ A8.inClass "a-zA-Z0-9!#$&+-.^_`|~"
        c <- peekChar
        return $ case c of
            Just '*' -> B8.snoc name '*'
            _ -> name

data Quot = Literal | Backslash
