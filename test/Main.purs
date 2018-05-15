module Test.Main where

import Prelude

import Data.Either (Either(..))
import Data.Traversable (traverse_)
import Data.Variant as Variant
import Effect (Effect)
import Effect.Console (log)
import Hibachi (NoMatch(..), RouteURL, matchRoutes)
import Type.Prelude (RProxy(..))

type RouteURLs =
  ( hello :: RouteURL "/hello/{name}"
  , age :: RouteURL "/age/{age:Int}"
  , answer :: RouteURL "/gimme/{item:String}/{count:Int}"
  )

main :: Effect Unit
main = do
  let
    -- inferred type:
    -- (matchRoutes' :: String
    --     -> Either
    --          NoMatch
    --          (Variant
    --             ( hello :: { name :: String}
    --             , age :: { age :: Int }
    --             , answer :: { item :: String , count :: Int }
    --             )
    --         )
    -- ) =
    matchRoutes' =
      matchRoutes (RProxy :: RProxy RouteURLs)

    testRoutes =
      [ "/hello/Bill"
      , "/age/12"
      , "/gimme/Apple/24"
      , "/no/match"
      ]

    results = matchRoutes' <$> testRoutes
    handleResult = case _ of
      Left (NoMatch l) ->
        log $ "no match for: " <> show l
      Right r ->
        Variant.match
          { hello: \x -> log $ "hello your name is " <> x.name
          , age: \x -> log $ "hello you are " <> show x.age
          , answer: \x -> log $ "you want " <> show x.count <> " of " <> x.item
          }
          r

  traverse_ handleResult results

  -- result:
  -- hello your name is Bill
  -- hello you are 12
  -- you want 24 of Apple
  -- no match for: "/no/match"
