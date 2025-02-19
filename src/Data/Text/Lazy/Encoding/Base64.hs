{-# LANGUAGE DataKinds #-}
{-# LANGUAGE Safe #-}
-- |
-- Module       : Data.Text.Lazy.Encoding.Base64
-- Copyright    : (c) 2019-2022 Emily Pillmore
-- License      : BSD-style
--
-- Maintainer   : Emily Pillmore <emilypi@cohomolo.gy>
-- Stability    : stable
-- Portability  : non-portable
--
-- This module contains 'Data.Text.Lazy.Text'-valued combinators
-- implementing the RFC 4648 specification for the Base64
-- encoding format. This includes lenient decoding variants, and
-- external + internal validations for canonicity.
--
module Data.Text.Lazy.Encoding.Base64
( -- * Encoding
  encodeBase64
  -- * Decoding
, decodeBase64
, decodeBase64With
, decodeBase64Lenient
  -- * Validation
, isBase64
, isValidBase64
) where


import Data.Base64.Types

import Data.Bifunctor (first)
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy.Base64 as BL64

import qualified Data.Text as T
import Data.Text.Encoding.Base64.Error
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL

-- | Encode a 'TL.Text' value in Base64 with padding.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Examples__:
--
-- >>> encodeBase64 "Sun"
-- "U3Vu"
--
encodeBase64 :: TL.Text -> Base64 'StdPadded TL.Text
encodeBase64 = BL64.encodeBase64 . TL.encodeUtf8
{-# INLINE encodeBase64 #-}

-- | Decode a padded Base64-encoded 'TL.Text' value
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- /Note:/ This function makes sure that decoding is total by deferring to
-- 'T.decodeLatin1'. This will always round trip for any valid Base64-encoded
-- text value, but it may not round trip for bad inputs. The onus is on the
-- caller to make sure inputs are valid. If unsure, defer to `decodeBase64With`
-- and pass in a custom decode function.
--
-- === __Examples__:
--
-- >>> decodeBase64 "U3Vu"
-- Right "Sun"
--
-- >>> decodeBase64 "U3V"
-- Left "Base64-encoded bytestring requires padding"
--
-- >>> decodebase64 "U3V="
-- Left "non-canonical encoding detected at offset: 2"
--
decodeBase64 :: StdAlphabet k => Base64 k TL.Text -> Either T.Text TL.Text
decodeBase64 = fmap TL.decodeLatin1 . BL64.decodeBase64 . fmap TL.encodeUtf8
{-# INLINE decodeBase64 #-}

-- | Attempt to decode a 'ByteString' value as Base64, converting from
-- 'ByteString' to 'TL.Text' according to some encoding function. In practice,
-- This is something like 'decodeUtf8'', which may produce an error.
--
-- See: <https://tools.ietf.org/html/rfc4648#section-4 RFC-4648 section 4>
--
-- === __Example__:
--
-- @
-- 'decodeBase64With' 'TL.decodeUtf8''
--   :: 'ByteString' -> 'Either' ('Base64Error' 'UnicodeException') 'TL.Text'
-- @
--
decodeBase64With
    :: StdAlphabet k
    => (ByteString -> Either err TL.Text)
      -- ^ convert a bytestring to text (e.g. 'TL.decodeUtf8'')
    -> Base64 k ByteString
      -- ^ Input text to decode
    -> Either (Base64Error err) TL.Text
decodeBase64With f t = case BL64.decodeBase64 t of
  Left de -> Left $ DecodeError de
  Right a -> first ConversionError (f a)
{-# INLINE decodeBase64With #-}

-- | Leniently decode a Base64-encoded 'TL.Text' value. This function
-- will not generate parse errors. If input data contains padding chars,
-- then the input will be parsed up until the first pad character.
--
-- __Note:__ This is not RFC 4648-compliant.
--
-- === __Examples__:
--
-- >>> decodeBase64Lenient "U3Vu"
-- "Sun"
--
-- >>> decodeBase64Lenient "U3V"
-- "Su"
--
-- >>> decodebase64Lenient "U3V="
-- "Su"
--
decodeBase64Lenient :: Base64 k TL.Text -> TL.Text
decodeBase64Lenient = TL.decodeLatin1
    . BL64.decodeBase64Lenient
    . fmap TL.encodeUtf8
{-# INLINE decodeBase64Lenient #-}

-- | Tell whether a 'TL.Text' value is Base64-encoded.
--
-- === __Examples__:
--
-- >>> isBase64 "U3Vu"
-- True
--
-- >>> isBase64 "U3V"
-- False
--
-- >>> isBase64 "U3V="
-- False
--
isBase64 :: TL.Text -> Bool
isBase64 = BL64.isBase64 . TL.encodeUtf8
{-# INLINE isBase64 #-}

-- | Tell whether a 'TL.Text' value is a valid Base64 format.
--
-- This will not tell you whether or not this is a correct Base64 representation,
-- only that it conforms to the correct shape. To check whether it is a true
-- Base64 encoded 'TL.Text' value, use 'isBase64'.
--
-- === __Examples__:
--
-- >>> isValidBase64 "U3Vu"
-- True
--
-- >>> isValidBase64 "U3V"
-- True
--
-- >>> isValidBase64 "U3V="
-- True
--
-- >>> isValidBase64 "%"
-- False
--
isValidBase64 :: TL.Text -> Bool
isValidBase64 = BL64.isValidBase64 . TL.encodeUtf8
{-# INLINE isValidBase64 #-}
