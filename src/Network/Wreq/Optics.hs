{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

-- |
-- Module      : Network.Wreq.Optics
-- Description : Optics-based replacements for wreq's lens API
--
-- This module provides optics (from the @optics@ library) that are
-- equivalent to the lenses provided by "Network.Wreq.Lens" (which
-- uses the @lens@ library).
--
-- The van Laarhoven lenses from wreq are converted to optics using
-- 'lensVL' and 'traversalVL' from @optics-core@.
--
-- When reading the examples in this module, you should assume the
-- following environment:
--
-- @
-- \-\- Make it easy to write literal 'S.ByteString' and 'Text' values.
-- \{\-\# LANGUAGE OverloadedStrings \#\-\}
--
-- \-\- Our handy module.
-- import "Network.Wreq"
--
-- \-\- Optics operators.
-- import "Optics.Core"
--
-- \-\- Conversion of Haskell values to JSON.
-- import "Data.Aeson" ('Data.Aeson.toJSON')
-- @
module Network.Wreq.Optics
  ( -- * Configuration
    Options
  , manager
  , proxy
  , auth
  , header
  , param
  , redirects
  , headers
  , params
  , cookie
  , cookies
  , ResponseChecker
  , checkResponse

    -- ** Proxy setup
  , Proxy
  , proxyHost
  , proxyPort

    -- * Cookie
  , Cookie
  , cookieName
  , cookieValue
  , cookieExpiryTime
  , cookieDomain
  , cookiePath
  , cookieCreationTime
  , cookieLastAccessTime
  , cookiePersistent
  , cookieHostOnly
  , cookieSecureOnly
  , cookieHttpOnly

    -- * Response
  , Response
  , responseBody
  , responseHeader
  , responseLink
  , responseCookie
  , responseHeaders
  , responseCookieJar
  , responseStatus
  , responseVersion

    -- * HistoriedResponse
  , HistoriedResponse
  , hrFinalResponse
  , hrFinalRequest
  , hrRedirects

    -- ** Status
  , Status
  , statusCode
  , statusMessage

    -- * Link header
  , Link
  , linkURL
  , linkParams

    -- * POST body part
  , Part
  , partName
  , partFileName
  , partContentType
  , partGetBody

    -- * Parsing
  , atto
  , atto_
  ) where

import Control.Applicative (many)
import Data.Attoparsec.ByteString (Parser, endOfInput, parseOnly)
import qualified Data.Attoparsec.ByteString.Char8 as A8
import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as B8
import qualified Data.ByteString.Lazy as L
import Data.Text (Text)
import Data.Time.Clock (UTCTime)
import Network.HTTP.Client
  ( Cookie, CookieJar, HistoriedResponse, Manager, ManagerSettings
  , Proxy, Request, RequestBody, Response
  )
import qualified Network.HTTP.Client as HTTP
import Network.HTTP.Client.MultipartFormData (Part)
import Network.HTTP.Types.Header (Header, HeaderName, ResponseHeaders)
import Network.HTTP.Types.Status (Status)
import Network.HTTP.Types.Version (HttpVersion)
import Network.Mime (MimeType)
import Network.Wreq.Types (Auth, Link(Link), Options, ResponseChecker)
import qualified Network.Wreq.Lens as WL
import Optics.Core
  ( Fold, Lens, Lens', Traversal'
  , (%), folding, filtered, lensVL, traversalVL
  )

-- * Configuration

-- | A lens onto configuration of the connection manager provided by
-- the http-client package.
--
-- In this example, we enable the use of TLS for (hopefully)
-- secure connections:
--
-- @
--import "Network.HTTP.Client.TLS"
--
--let opts = 'Network.Wreq.defaults' & 'set' 'manager' (Left 'Network.HTTP.Client.TLS.tlsManagerSettings')
--'Network.Wreq.getWith' opts \"https:\/\/httpbin.org\/get\"
-- @
--
-- See: 'Network.Wreq.Lens.manager'
manager :: Lens' Options (Either ManagerSettings Manager)
manager = lensVL WL.manager

-- | A lens onto proxy configuration.
--
-- Example:
--
-- @
--let opts = 'Network.Wreq.defaults' & 'set' 'proxy' ('Just' ('Network.Wreq.httpProxy' \"localhost\" 8000))
--'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/get\"
-- @
--
-- See: 'Network.Wreq.Lens.proxy'
proxy :: Lens' Options (Maybe Proxy)
proxy = lensVL WL.proxy

-- | A lens onto request authentication.
--
-- Example (note the use of TLS):
--
-- @
--let opts = 'Network.Wreq.defaults' & 'set' 'auth' ('Just' ('Network.Wreq.basicAuth' \"user\" \"pass\"))
--'Network.Wreq.getWith' opts \"https:\/\/httpbin.org\/basic-auth\/user\/pass\"
-- @
--
-- See: 'Network.Wreq.Lens.auth'
auth :: Lens' Options (Maybe Auth)
auth = lensVL WL.auth

-- | A lens onto all headers with the given name (there can
-- legitimately be zero or more).
--
-- Example:
--
-- @
--let opts = 'Network.Wreq.defaults' & 'set' ('header' \"Accept\") [\"*\/*\"]
--'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/get\"
-- @
--
-- See: 'Network.Wreq.Lens.header'
header :: HeaderName -> Lens' Options [ByteString]
header n = lensVL (WL.header n)

-- | A lens onto all headers (there can legitimately be zero or more).
--
-- In this example, we print all the headers sent by default with
-- every request.
--
-- @
--print ('view' 'headers' 'Network.Wreq.defaults')
-- @
--
-- See: 'Network.Wreq.Lens.headers'
headers :: Lens' Options [Header]
headers = lensVL WL.headers

-- | A lens onto all query parameters with the given name (there can
-- legitimately be zero or more).
--
-- In this example, we construct the query URL
-- \"@http:\/\/httpbin.org\/get?foo=bar&foo=quux@\".
--
-- @
--let opts = 'Network.Wreq.defaults' & 'set' ('param' \"foo\") [\"bar\", \"quux\"]
--'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/get\"
-- @
--
-- See: 'Network.Wreq.Lens.param'
param :: Text -> Lens' Options [Text]
param n = lensVL (WL.param n)

-- | A lens onto all query parameters.
--
-- See: 'Network.Wreq.Lens.params'
params :: Lens' Options [(Text, Text)]
params = lensVL WL.params

-- | A lens onto the maximum number of redirects that will be followed
-- before an exception is thrown.
--
-- In this example, a 'Network.HTTP.Client.HttpException' will be
-- thrown with a 'Network.HTTP.Client.TooManyRedirects' constructor,
-- because the maximum number of redirects allowed will be exceeded.
--
-- @
--let opts = 'Network.Wreq.defaults' & 'set' 'redirects' 3
--'Network.Wreq.getWith' opts \"http:\/\/httpbin.org\/redirect\/5\"
-- @
--
-- See: 'Network.Wreq.Lens.redirects'
redirects :: Lens' Options Int
redirects = lensVL WL.redirects

-- | A lens to get the optional status check function.
--
-- See: 'Network.Wreq.Lens.checkResponse'
checkResponse :: Lens' Options (Maybe ResponseChecker)
checkResponse = lensVL WL.checkResponse

-- | A lens onto all cookies.
--
-- See: 'Network.Wreq.Lens.cookies'
cookies :: Lens' Options (Maybe CookieJar)
cookies = lensVL WL.cookies

-- | A traversal onto the cookie with the given name, if one exists.
--
-- N.B. This is an \"illegal\" 'Traversal'': we can change the
-- 'cookieName' of the associated 'Cookie' so that it differs from the
-- name provided to this function.
--
-- See: 'Network.Wreq.Lens.cookie'
cookie :: ByteString -> Traversal' Options Cookie
cookie n = traversalVL (WL.cookie n)

-- ** Proxy setup

-- | A lens onto the hostname portion of a proxy configuration.
--
-- See: 'Network.Wreq.Lens.proxyHost'
proxyHost :: Lens' Proxy ByteString
proxyHost = lensVL WL.proxyHost

-- | A lens onto the TCP port number of a proxy configuration.
--
-- See: 'Network.Wreq.Lens.proxyPort'
proxyPort :: Lens' Proxy Int
proxyPort = lensVL WL.proxyPort

-- * Cookie

-- | A lens onto the name of a cookie.
--
-- See: 'Network.Wreq.Lens.cookieName'
cookieName :: Lens' Cookie ByteString
cookieName = lensVL WL.cookieName

-- | A lens onto the value of a cookie.
--
-- See: 'Network.Wreq.Lens.cookieValue'
cookieValue :: Lens' Cookie ByteString
cookieValue = lensVL WL.cookieValue

-- | A lens onto the expiry time of a cookie.
--
-- See: 'Network.Wreq.Lens.cookieExpiryTime'
cookieExpiryTime :: Lens' Cookie UTCTime
cookieExpiryTime = lensVL WL.cookieExpiryTime

-- | A lens onto the domain of a cookie.
--
-- See: 'Network.Wreq.Lens.cookieDomain'
cookieDomain :: Lens' Cookie ByteString
cookieDomain = lensVL WL.cookieDomain

-- | A lens onto the path of a cookie.
--
-- See: 'Network.Wreq.Lens.cookiePath'
cookiePath :: Lens' Cookie ByteString
cookiePath = lensVL WL.cookiePath

-- | A lens onto the creation time of a cookie.
--
-- See: 'Network.Wreq.Lens.cookieCreationTime'
cookieCreationTime :: Lens' Cookie UTCTime
cookieCreationTime = lensVL WL.cookieCreationTime

-- | A lens onto the last access time of a cookie.
--
-- See: 'Network.Wreq.Lens.cookieLastAccessTime'
cookieLastAccessTime :: Lens' Cookie UTCTime
cookieLastAccessTime = lensVL WL.cookieLastAccessTime

-- | A lens onto whether a cookie is persistent across sessions (also
-- known as a \"tracking cookie\").
--
-- See: 'Network.Wreq.Lens.cookiePersistent'
cookiePersistent :: Lens' Cookie Bool
cookiePersistent = lensVL WL.cookiePersistent

-- | A lens onto whether a cookie is host-only.
--
-- See: 'Network.Wreq.Lens.cookieHostOnly'
cookieHostOnly :: Lens' Cookie Bool
cookieHostOnly = lensVL WL.cookieHostOnly

-- | A lens onto whether a cookie is secure-only, such that it will
-- only be used over TLS.
--
-- See: 'Network.Wreq.Lens.cookieSecureOnly'
cookieSecureOnly :: Lens' Cookie Bool
cookieSecureOnly = lensVL WL.cookieSecureOnly

-- | A lens onto whether a cookie is \"HTTP-only\".
--
-- Such cookies should be used only by browsers when transmitting HTTP
-- requests.  They must be unavailable in non-browser environments,
-- such as when executing JavaScript scripts.
--
-- See: 'Network.Wreq.Lens.cookieHttpOnly'
cookieHttpOnly :: Lens' Cookie Bool
cookieHttpOnly = lensVL WL.cookieHttpOnly

-- * Response

-- | A lens onto the status of an HTTP response.
--
-- See: 'Network.Wreq.Lens.responseStatus'
responseStatus :: Lens' (Response body) Status
responseStatus = lensVL WL.responseStatus

-- | A lens onto the version of an HTTP response.
--
-- See: 'Network.Wreq.Lens.responseVersion'
responseVersion :: Lens' (Response body) HttpVersion
responseVersion = lensVL WL.responseVersion

-- | A lens onto all headers in an HTTP response.
--
-- See: 'Network.Wreq.Lens.responseHeaders'
responseHeaders :: Lens' (Response body) ResponseHeaders
responseHeaders = lensVL WL.responseHeaders

-- | A lens onto the body of a response.
--
-- @
--r <- 'Network.Wreq.get' \"http:\/\/httpbin.org\/get\"
--print ('view' 'responseBody' r)
-- @
--
-- See: 'Network.Wreq.Lens.responseBody'
responseBody :: Lens (Response body0) (Response body1) body0 body1
responseBody = lensVL WL.responseBody

-- | A lens onto all cookies set in the response.
--
-- See: 'Network.Wreq.Lens.responseCookieJar'
responseCookieJar :: Lens' (Response body) CookieJar
responseCookieJar = lensVL WL.responseCookieJar

-- | A traversal onto all matching named headers in an HTTP response.
--
-- To access the first matching header, use 'Optics.Core.preview':
--
-- @
--r <- 'Network.Wreq.get' \"http:\/\/httpbin.org\/get\"
--print ('preview' ('responseHeader' \"Content-Type\") r)
-- @
--
-- To access all (zero or more) matching headers, use 'Optics.Core.toListOf':
--
-- @
--r <- 'Network.Wreq.get' \"http:\/\/httpbin.org\/get\"
--print ('toListOf' ('responseHeader' \"Set-Cookie\") r)
-- @
--
-- See: 'Network.Wreq.Lens.responseHeader'
responseHeader :: HeaderName
               -- ^ Header name to match.
               -> Traversal' (Response body) ByteString
responseHeader n = traversalVL (WL.responseHeader n)

-- | A fold over any cookies that match the given name.
--
-- @
--r <- 'Network.Wreq.get' \"http:\/\/www.nytimes.com\/\"
--print ('preview' ('responseCookie' \"RMID\") r)
-- @
--
-- See: 'Network.Wreq.Lens.responseCookie'
responseCookie :: ByteString
               -- ^ Name of cookie to match.
               -> Fold (Response body) Cookie
responseCookie name =
  lensVL WL.responseCookieJar % folding HTTP.destroyCookieJar
    % filtered ((== name) . HTTP.cookie_name)

-- | A fold over @Link@ headers, matching on both parameter name
-- and value.
--
-- For example, here is a @Link@ header returned by the GitHub search API.
--
-- > Link:
-- >   <https://api.github.com/search/code?q=addClass+user%3Amozilla&page=2>; rel="next",
-- >   <https://api.github.com/search/code?q=addClass+user%3Amozilla&page=34>; rel="last"
--
-- And here is an example of how we can retrieve the URL for the @next@ link
-- programatically.
--
-- @
--r <- 'Network.Wreq.get' \"https:\/\/api.github.com\/search\/code?q=addClass+user:mozilla\"
--print ('preview' ('responseLink' \"rel\" \"next\" '%' 'linkURL') r)
-- @
--
-- See: 'Network.Wreq.Lens.responseLink'
responseLink :: ByteString
             -- ^ Parameter name to match.
             -> ByteString
             -- ^ Parameter value to match.
             -> Fold (Response body) Link
responseLink name val =
  responseHeader "Link" % folding parseLinks
    % filtered (\(Link _ ps) -> (name, val) `elem` ps)

-- * HistoriedResponse

-- | A lens onto the final request of a historied response.
--
-- See: 'Network.Wreq.Lens.hrFinalRequest'
hrFinalRequest :: Lens' (HistoriedResponse body) Request
hrFinalRequest = lensVL WL.hrFinalRequest

-- | A lens onto the final response of a historied response.
--
-- See: 'Network.Wreq.Lens.hrFinalResponse'
hrFinalResponse :: Lens' (HistoriedResponse body) (Response body)
hrFinalResponse = lensVL WL.hrFinalResponse

-- | A lens onto the list of redirects of a historied response.
--
-- See: 'Network.Wreq.Lens.hrRedirects'
hrRedirects :: Lens' (HistoriedResponse body) [(Request, Response L.ByteString)]
hrRedirects = lensVL WL.hrRedirects

-- ** Status

-- | A lens onto the numeric identifier of an HTTP status.
--
-- See: 'Network.Wreq.Lens.statusCode'
statusCode :: Lens' Status Int
statusCode = lensVL WL.statusCode

-- | A lens onto the textual description of an HTTP status.
--
-- See: 'Network.Wreq.Lens.statusMessage'
statusMessage :: Lens' Status ByteString
statusMessage = lensVL WL.statusMessage

-- * Link header

-- | A lens onto the URL portion of a @Link@ element.
--
-- See: 'Network.Wreq.Lens.linkURL'
linkURL :: Lens' Link ByteString
linkURL = lensVL WL.linkURL

-- | A lens onto the parameters of a @Link@ element.
--
-- See: 'Network.Wreq.Lens.linkParams'
linkParams :: Lens' Link [(ByteString, ByteString)]
linkParams = lensVL WL.linkParams

-- * POST body part

-- | A lens onto the name of the @\<input\>@ element associated with
-- part of a multipart form upload.
--
-- See: 'Network.Wreq.Lens.partName'
partName :: Lens' Part Text
partName = lensVL WL.partName

-- | A lens onto the filename associated with part of a multipart form
-- upload.
--
-- See: 'Network.Wreq.Lens.partFileName'
partFileName :: Lens' Part (Maybe String)
partFileName = lensVL WL.partFileName

-- | A lens onto the content-type associated with part of a multipart
-- form upload.
--
-- See: 'Network.Wreq.Lens.partContentType'
partContentType :: Traversal' Part (Maybe MimeType)
partContentType = traversalVL WL.partContentType

-- | A lens onto the code that fetches the data associated with part
-- of a multipart form upload.
--
-- See: 'Network.Wreq.Lens.partGetBody'
partGetBody :: Lens' Part (IO RequestBody)
partGetBody = lensVL WL.partGetBody

-- * Parsing

-- | Turn an attoparsec 'Parser' into a 'Fold'.
--
-- Both headers and bodies can contain complicated data that we may
-- need to parse.
--
-- Example: when responding to an OPTIONS request, a server may return
-- the list of verbs it supports in any order, up to and including
-- changing the order on every request (which httpbin.org /actually
-- does/!).  To deal with this possibility, we parse the list, then
-- sort it.
--
-- @
--import Data.Attoparsec.ByteString.Char8 as A
--import Data.List (sort)
--
--let comma = skipSpace >> \",\" >> skipSpace
--let verbs = A.takeWhile isAlpha_ascii \`sepBy\` comma
--
--r <- 'Network.Wreq.options' \"http:\/\/httpbin.org\/get\"
--'toListOf' ('responseHeader' \"Allow\" '%' 'atto' verbs '%' 'to' sort) r
-- @
--
-- See: 'Network.Wreq.Lens.atto'
atto :: Parser a -> Fold ByteString a
atto p = folding (parseOnly p)

-- | The same as 'atto', but ensures that the parser consumes the
-- entire input.
--
-- Equivalent to:
--
-- @
--'atto_' myParser = 'atto' (myParser '<*' 'endOfInput')
-- @
--
-- See: 'Network.Wreq.Lens.atto_'
atto_ :: Parser a -> Fold ByteString a
atto_ p = atto (p <* endOfInput)

-- * Link header parser (reimplemented from wreq internals)

parseLinks :: ByteString -> [Link]
parseLinks hdr = case parseOnly linksP hdr of
  Left _   -> []
  Right xs -> xs
  where
    linksP = A8.sepBy1 linkP (A8.skipSpace *> A8.char ',' *> A8.skipSpace) <* endOfInput
    linkP = Link
      <$> (A8.char '<' *> A8.takeTill (== '>') <* A8.char '>' <* A8.skipSpace)
      <*> many (A8.char ';' *> A8.skipSpace *> paramP)
    paramP = do
      n <- A8.takeWhile1 (A8.inClass "a-zA-Z0-9!#$&+-.^_`|~")
      c <- A8.peekChar
      let n' = case c of
                 Just '*' -> n <> "*"
                 _        -> n
      A8.skipSpace *> A8.char '=' *> A8.skipSpace
      c2 <- A8.peekChar'
      v <- case c2 of
             '"' -> quotedStr
             _   -> A8.takeWhile (A8.inClass "!#$%&'()*+./0-9:<=>?@a-zA-Z[]^_`{|}~-")
      A8.skipSpace
      return (n', v)
    quotedStr = A8.char '"' *> (fixup <$> A8.scan Literal scanQ) <* A8.char '"'
    fixup = B8.pack . go . B8.unpack
      where go ('\\' : x@'\\' : xs) = x : go xs
            go ('\\' : x@'"' : xs)  = x : go xs
            go (x : xs)             = x : go xs
            go xs                   = xs

data Quot = Literal | Backslash

scanQ :: Quot -> Char -> Maybe Quot
scanQ Literal '\\' = Just Backslash
scanQ Literal '"'  = Nothing
scanQ _       _    = Just Literal
